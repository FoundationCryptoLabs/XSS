pragma solidity 0.6.7;

import "./dsmath.sol";


contract CoinLike{
  mapping (address => uint256)                      public balanceOf;
  // Mapping of allowances
  mapping (address => mapping (address => uint256)) public allowance;
  // Mapping of nonces used for permits
  mapping (address => uint256)                      public nonces;
  function addAuthorization(address account) external {}
  function removeAuthorization(address account) external {}
  function transfer(address dst, uint256 amount) external returns (bool) {}
  function transferFrom(address src, address dst, uint256 amount)
        public returns (bool){}
  function mint(address usr, uint256 amount) external {}
  function burn(address usr, uint256 amount) external {}
  function approve(address usr, uint256 amount) external returns (bool) {}
  function push(address usr, uint256 amount) external {}
  function pull(address usr, uint256 amount) external {}
  function move(address src, address dst, uint256 amount) external {}
  function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external
    {}
}

contract OracleLike{
  function addAuthorization(address account) external {}
  function removeAuthorization(address account) external {}
  function setCollateralRatio(uint256 ratio) external {}
  function peekCollateralRatio() external returns(uint256) {}
  function peekBSMA() external returns(uint256){}
  function peekBX() external returns(uint256){}


}

contract TaxCollectorLike{
  function updateAR() public returns (uint256) {}
  function updateAccumulatedRate() public returns (uint128) {}
}
contract CDPTracker is DSMath {

address Oracle;
address Coin;
uint256 dust; //Minimum amount of collateral deposited
uint256 Interest; // Interest rate set by governance. Applies from next calculation after rate is set.

uint256 totalDebt;
uint256 public globalDebt;
uint256 totalSurplus;
uint256 public lastAR; // last AR for system surplus calculation.
uint256 RATE = 1*10**27; // RAY - base value of AR.
uint256 public INIT;

uint128 globalStabilityFee= 1000000564701133626865910626; //[ray] per second rate, 5% per day setting for testing.
// TaxCollectorLike TC = TaxCollectorLike(0xd275F1D2fceB349dF85c7DF7ED7572EE8ccdf20f); // RSK testnet address
TaxCollectorLike TC = TaxCollectorLike(0xFB1dFE7b4c479fc6383e21d42c51127bFcB44b3F);
// mapping (address => uint256) LastupdateTime;
// mapping (address => uint128) originRate;

struct SAFE {
    // Total amount of collateral locked in a SAFE
      uint256 collateral;
      // Total amount of debt generated by a SAFE, including interest
      uint256 debtIssued;  // [wad]
      // last interest rate update timestamp
      uint256 updateTime;     // [wad]
      // global AR at last update
      uint256 originRate; // [RAY]
  }

mapping (address=>uint256) public collateral; // collateral deposited by UserAddress
mapping (address=>uint256) public debtIssued; // debt issued by UserAddress
// mapping (address=>uint256) public interestDue; // interest due by UserAddress
mapping (address=>uint256) public initTime;
mapping (address => SAFE) public safes;

uint256 LastupdateTime;
OracleLike Orc;
CoinLike coin;

constructor(address ORC, uint256 DUST) public {
  Oracle = ORC;
  dust = DUST;
  authorizedAccounts[msg.sender] = 1;
  INIT = block.timestamp;
}
event AddAuthorization(address account);
event RemoveAuthorization(address account);

mapping (address => uint256) public authorizedAccounts;
/**
 * @notice Add auth to an account
 * @param account Account to add auth to
 */
function addAuthorization(address account) external isAuthorized {
    authorizedAccounts[account] = 1;
    emit AddAuthorization(account);
}
/**
 * @notice Remove auth from an account
 * @param account Account to remove auth from
 */
function removeAuthorization(address account) external isAuthorized {
    authorizedAccounts[account] = 0;
    emit RemoveAuthorization(account);
}
/**
* @notice Checks whether msg.sender can call an authed function
**/
modifier isAuthorized {
    require(authorizedAccounts[msg.sender] == 1, "Coin/account-not-authorized");
    _;
}



// math
function add(uint256 x, int256 y) internal pure returns (uint256 z) {
    z = x + uint256(y);
    require(y >= 0 || z <= x, "SAFEEngine/add-uint-int-overflow");
    require(y <= 0 || z >= x, "SAFEEngine/add-uint-int-underflow");
}
function add(int256 x, int256 y) internal pure returns (int256 z) {
    z = x + y;
    require(y >= 0 || z <= x, "SAFEEngine/add-int-int-overflow");
    require(y <= 0 || z >= x, "SAFEEngine/add-int-int-underflow");
}
function sub(uint256 x, int256 y) internal pure returns (uint256 z) {
    z = x - uint256(y);
    require(y <= 0 || z <= x, "SAFEEngine/sub-uint-int-overflow");
    require(y >= 0 || z >= x, "SAFEEngine/sub-uint-int-underflow");
}
function sub(int256 x, int256 y) internal pure returns (int256 z) {
    z = x - y;
    require(y <= 0 || z <= x, "SAFEEngine/sub-int-int-overflow");
    require(y >= 0 || z >= x, "SAFEEngine/sub-int-int-underflow");
}
function mul(uint256 x, int256 y) internal pure returns (int256 z) {
    z = int256(x) * y;
    require(int256(x) >= 0, "SAFEEngine/mul-uint-int-null-x");
    require(y == 0 || z / y == int256(x), "SAFEEngine/mul-uint-int-overflow");
}
function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x);
}

function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "SAFEEngine/add-uint-uint-overflow");
}
function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "SAFEEngine/sub-uint-uint-underflow");
}


function setCoin(address STABLE) external isAuthorized {
  Coin = STABLE;
}

// Called by Executor.sol when governance votes to change interest rate.
function setInterest(uint128 StabilityFee) external isAuthorized {
  globalStabilityFee = StabilityFee;
}

// Function called by TaxCollector Contract
function newAR(uint256 newRATE) external isAuthorized {
  RATE = newRATE;
}

// Function called by TaxCollector Contract
function updateGlobalDebt(uint256 newDebt) external isAuthorized {
  globalDebt = newDebt;
}

function gsafes(address account, string memory entry1) public returns(uint256){
  bytes memory entry = bytes(entry1);
  SAFE memory newsafe = safes[account];
  if(keccak256(entry) == keccak256("collateral")){
    return newsafe.collateral;
  }
  if(keccak256(entry) == keccak256("debtissued")){
    return newsafe.debtIssued;
  }
  if(keccak256(entry) == keccak256("updatetime")){
    return newsafe.updateTime;
  }      // [wad]
  if(keccak256(entry) == keccak256("originrate")){
    return newsafe.originRate;
  }
}
// Function called by TaxCollector Contract
function issueSurplus(uint256 amount, address treasury) external isAuthorized {
    coin = CoinLike(Coin);
    coin.mint(treasury, amount);
  }

// Actual function with proper time.
function updateUserDebt(address user) public returns(uint256) {
  // uint256 timeDifference = sub(now, LastupdateTime[user]);
  uint256 newDebt = safes[user].debtIssued;
  if (now >= safes[user].updateTime) {
  uint256 originalrate = safes[user].originRate;
  uint128 newrate= TC.updateAccumulatedRate();
  // uint256 newDebt = rmul(debtIssued[user], rpow(accumulatedRate, timeDifference));
  // uint256 newDebt = ((NewRate/OriginRate)*safes[msg.sender].debtIssued)/10000;
  uint256 newDebt = rmul(rdiv(newrate, originalrate), safes[user].debtIssued);
  safes[user].originRate = newrate;
  uint256 newTime = now;
  // safes[user].debtIssued = newDebt;
  // LastupdateTime[user] - newTime;
  safes[user].debtIssued = newDebt;
  safes[user].updateTime = newTime;
}
  return newDebt;

}

// test - hardcoded value of time elapsed.
function updateAccumulatedRate0() public returns (uint256) {
  uint64 powertime = 6; //[wad] replace with time gap since last update
  //uint64 powertime = block.timestamp - INIT
  uint256 rateupdate = rpow(globalStabilityFee, powertime);
  RATE=uint128(rateupdate);
  return RATE;
  }

// test - hardcoded value of time elapsed.
function updateAccumulatedRate1() public returns (uint256) {
  uint64 powertime = 86406; // set to 1 day by default. replace with time gap since last update using
  //uint64 powertime = block.timestamp - INIT
  uint256 rateupdate = rpow(globalStabilityFee, powertime);
  RATE=uint128(rateupdate);
  return RATE;
  }

// Test function
function updateUserDebt1(address user) public returns(uint256) {
  // uint256 timeDifference = sub(now, LastupdateTime[user]);
  // uint256 NewRate = 101000000000;
  // uint256 OriginRate = 1000000000;
  uint256 originalrate = safes[msg.sender].originRate;
  // uint256 newrate= TC.updateAR();
  uint256 newrate = updateAccumulatedRate0();
  // uint256 newDebt = rmul(debtIssued[user], rpow(accumulatedRate, timeDifference));
  uint256 newDebt = rmul(rdiv(newrate, originalrate), safes[msg.sender].debtIssued);
  //uint256 newTime = now;
  safes[user].debtIssued = newDebt;
  // LastupdateTime[user] = newTime;
  safes[user].originRate = newrate;
  uint256 newTime = now;
  safes[user].updateTime = newTime;
  return newDebt;
}

// Test function
function updateUserDebt2(address user) public returns(uint256) {
  // uint256 timeDifference = sub(now, LastupdateTime[user]);
  // uint256 NewRate = 101000000000;
  // uint256 OriginRate = 1000000000;
  uint256 originalrate = safes[msg.sender].originRate;
  // uint256 newrate= TC.updateAR();
  uint256 newrate = updateAccumulatedRate1();
  // uint256 newDebt = rmul(debtIssued[user], rpow(accumulatedRate, timeDifference));
  uint256 newDebt = rmul(rdiv(newrate, originalrate), safes[msg.sender].debtIssued);
  //uint256 newTime = now;
  safes[user].debtIssued = newDebt;
  // LastupdateTime[user] = newTime;
  safes[user].originRate = newrate;
  uint256 newTime = now;
  safes[user].updateTime = newTime;
  return newDebt;
}

// compute debt limit based on collateral deposited
function computeDebtLimit(address _oracle) internal returns (uint256){
   Orc = OracleLike(_oracle);
   uint256 _collateral = safes[msg.sender].collateral; //Amount of RBTC Collateral in SAFE
   uint256 currentBX = Orc.peekBX();
   uint256 currentCollateralRatio = Orc.peekCollateralRatio(); //12500 by default, to be divided by 100
   uint256 currentDebtLimit = _collateral * currentCollateralRatio / 100; // 1 xBTC can be minted (borrowed) for every 1.25 BTC collateral by default.
   return currentDebtLimit;
 }

// compute redeem price in BTC for each xBTC
 function computeRedeemPrice(address _oracle) internal returns (uint256){
   Orc = OracleLike(_oracle);
   uint256 currentBX = Orc.peekBX(); //BTC-USD exchange rate
   uint256 currentBSMA = Orc.peekBSMA(); //Current USD redemption rate of 1 xBTC
   uint256 currentRedeemPrice = (currentBSMA*1000000)/currentBX; //10e6 multiplier to preserve precision of fraction.
   return currentRedeemPrice;
 }

 function sendRBTC(address payable _to, uint256 amount) internal {
        // Call returns a boolean value indicating success or failure.
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        require(sent, "Failed to send RBTC");
    }

 // deposit RBTC collateral in safe
 function depositCollateral() public payable {
    require(msg.value>=dust, 'CDPTracker/non-dusty-collateral-required');
    safes[msg.sender].collateral = (safes[msg.sender].collateral) + msg.value;
  }

// take out xBTC debt
  function takeDebt(uint256 amount) public {
    safes[msg.sender].originRate = updateAccumulatedRate0();
    uint256 debtLimit = computeDebtLimit(Oracle);
    uint256 issuedDebt = updateUserDebt1(msg.sender);
    uint256 availableDebt = debtLimit - issuedDebt;
    require(availableDebt >= amount, "CDPTracker/insufficient-collateral-to-mint-stables"); //collateral sufficiency check
    coin = CoinLike(Coin);
    safes[msg.sender].debtIssued = add(safes[msg.sender].debtIssued, amount);
    globalDebt += amount;
    coin.mint(msg.sender, amount);
    safes[msg.sender].updateTime = now;

  }

// return xBTC debt
  function returnDebt(uint256 amount) public {
    uint256 issuedDebt = updateUserDebt2(msg.sender); // update balance to include interest. Replace with updateUserDebt in production.
    require(issuedDebt >= amount, "CDPTracker/exceeds-debt-amount");
    coin = CoinLike(Coin);
    safes[msg.sender].debtIssued = sub(safes[msg.sender].debtIssued, amount);
    globalDebt -= amount;
    coin.burn(msg.sender, amount);
  }

// redeem xBTC stablecoins for RBTC collateral at current redemption rate. Maintains price stability
  function redeemCoins(uint256 amount) public payable {
    coin = CoinLike(Coin);
    require(coin.balanceOf(msg.sender)>=amount, "CDPTracker/exceeds-balance");
    uint256 redemptionRatePerCoin = computeRedeemPrice(Oracle);
    uint256 totalRedemptionAmount = mul(redemptionRatePerCoin, amount)/1000000;
    coin.burn(msg.sender, amount);
    globalDebt -= amount;
    sendRBTC(msg.sender, totalRedemptionAmount);
  }

// withdraw collateral after debts have been repaid
  function removeCollateral(uint256 amount) public payable {
     require(amount>=dust, 'CDPTracker/non-dusty-collateral-required');
     uint256 _collateral = safes[msg.sender].collateral; //Amount of RBTC Collateral in CDP
     require(amount<=_collateral, 'CDPTracker/amount-exceeds-deposits');
     uint256 issuedDebt = safes[msg.sender].debtIssued;
     require(issuedDebt==0, 'CDPTracker/debt-not-repaid');
     safes[msg.sender].collateral = (safes[msg.sender].collateral) - amount;
     sendRBTC(msg.sender, amount);
   }

}
