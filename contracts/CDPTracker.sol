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
  function taxSingleOutcomeL() public returns (uint256) {}
}
contract CDPTracker is DSMath {

mapping (address=>uint256) public collateral; // collateral deposited by UserAddress
mapping (address=>uint256) public debtIssued; // debt issued by UserAddress
// mapping (address=>uint256) public interestDue; // interest due by UserAddress
mapping (address=>uint256) public initTime;
mapping (address => SAFE) public safes;


address Oracle;
address Coin;
uint256 dust; //Minimum amount of collateral deposited
uint256 Interest; // Interest rate set by governance. Applies from next calculation after rate is set.

uint256 totalDebt;
uint256 globalDebt;
uint256 totalInterest;
uint128 RATE = 10000000000000000000; //[wad] per second rate, 5% per day
uint256 ACCRATE;
uint256 AccruedDebt = 100000;
uint128 globalStabilityFee= 101000564701133626865910626;
uint256 accumulatedRate = 100000564701133626865910626;//100000000015815;
TaxCollectorLike TC = TaxCollectorLike(0x950fc41BA7Fe437121340955dBaEBe4dE8fb0EB5);

mapping (address => uint256) debtGenerated;
mapping (address => uint256) LastupdateTime;
mapping (address => uint256) accumulatedDebt;
mapping (address => uint256) originRate;

function updateDebt(address user) public returns(uint256) {
  // uint256 timeDifference = sub(now, LastupdateTime[user]);
  uint256 NewRate = 101000000000;
  uint256 OriginRate = 1000000000;
  uint256 originalrate = originRate[msg.sender];
  uint256 newrate= TC.taxSingleOutcomeL()*10000;
  // uint256 newDebt = rmul(debtIssued[user], rpow(accumulatedRate, timeDifference));
  // uint256 newDebt = ((NewRate/OriginRate)*debtIssued[msg.sender])/10000;
  uint256 newDebt = (newrate/originalrate)*debtIssued[msg.sender]/10000;

  uint256 newTime = now;
  debtIssued[user] = newDebt;
  LastupdateTime[user] = newTime;
  return newDebt;
}
function updateAccumulatedRate0() public returns (uint256) {
  uint128 lastAccumulatedRate = RATE;
  uint64 powertime = 6; //[wad] replace with time gap since last update
  uint256 rateupdate = rpow(globalStabilityFee, powertime);
  uint256 newrate =rmul(    // Only one collateral type.
     lastAccumulatedRate, rpow(globalStabilityFee, powertime));
  RATE=uint128(rateupdate);
  return RATE;
  }

function updateAccumulatedRate1() public returns (uint256) {
  uint128 lastAccumulatedRate = RATE;
  uint64 powertime = 8; //[wad] replace with time gap since last update
  uint256 rateupdate = rpow(globalStabilityFee, powertime);
  uint256 newrate =rmul(    // Only one collateral type.
     lastAccumulatedRate, rpow(globalStabilityFee, powertime));
  RATE=uint128(rateupdate);
  return RATE;
  }

function updateDebt2(address user) public returns(uint256) {
  // uint256 timeDifference = sub(now, LastupdateTime[user]);
  // uint256 NewRate = 101000000000;
  // uint256 OriginRate = 1000000000;
  uint256 originalrate = originRate[msg.sender];
  // uint256 newrate= TC.updateAR();
  uint256 newrate = updateAccumulatedRate1();
  // uint256 newDebt = rmul(debtIssued[user], rpow(accumulatedRate, timeDifference));
  uint256 newDebt = rmul(rdiv(newrate, originalrate), debtIssued[msg.sender]);
  //uint256 newTime = now;
  debtIssued[user] = newDebt;
  // LastupdateTime[user] = newTime;
  originRate[msg.sender] = newrate;
  return newDebt;
}

struct SAFE {
      // Total amount of collateral locked in a SAFE
      uint256 lockedCollateral;  // [wad]
      // Total amount of debt generated by a SAFE
      uint256 generatedDebt;     // [wad]
  }


OracleLike Orc;
CoinLike coin;

constructor(address ORC, uint256 DUST) public {
  Oracle = ORC;
  dust = DUST;
  authorizedAccounts[msg.sender] = 1;
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

event UpdateAccumulatedRate(
    address surplusDst,
    int256 rateMultiplier,
    uint256 globalDebt
);

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

function modifySAFECollateralization(
        bytes32 collateralType,
        address user,
        address collateralSource,
        address debtDestination,
        int256 deltaCollateral,
        int256 deltaDebt
    ) external {
        // system is live
        SAFE memory safeData = safes[user];

        safeData.lockedCollateral      = add(safeData.lockedCollateral, deltaCollateral);
        safeData.generatedDebt         = add(safeData.generatedDebt, deltaDebt);
        int256 deltaAdjustedDebt = mul(accumulatedRate, deltaDebt);
        uint256 totalDebtIssued  = mul(accumulatedRate, safeData.generatedDebt);
        globalDebt               = add(globalDebt, deltaAdjustedDebt);
      }

function computeDebtLimit(address _oracle) internal returns (uint256){
   Orc = OracleLike(_oracle);
   uint256 _collateral = collateral[msg.sender]; //Amount of RBTC Collateral in SAFE
   uint256 currentBX = Orc.peekBX();
   uint256 currentCollateralRatio = Orc.peekCollateralRatio(); //12500 by default, to be divided by 100
   uint256 currentDebtLimit = _collateral * currentCollateralRatio; // 1 xBTC can be minted (borrowed) for every 1.25 BTC collateral by default.
   return currentDebtLimit;
 }

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

 //deposit RBTC collateral in safe
 function depositCollateral() public payable {
    require(msg.value>=dust, 'CDPTracker/non-dusty-collateral-required');
    collateral[msg.sender] = (collateral[msg.sender]) + msg.value;
  }

  function _calculateInterest(address user) internal returns (uint256){


  }

  function takeDebt(uint256 amount) public {
    uint256 debtLimit = computeDebtLimit(Oracle);
    uint256 issuedDebt = debtIssued[msg.sender];
    uint256 availableDebt = debtLimit - issuedDebt;
    require(availableDebt >= amount, "CDPTracker/insufficient-collateral-to-mint-stables"); //collateral sufficiency check
    coin = CoinLike(Coin);
    debtIssued[msg.sender] = add(debtIssued[msg.sender], amount);
    totalDebt += amount;
    uint256 dS= amount*1000000000/totalDebt; // post-money share of debt
    // DebtShare[msg.sender] += dS;
    coin.mint(msg.sender, amount);
    LastupdateTime[msg.sender] = now;
    originRate[msg.sender] = updateAccumulatedRate0();
  }

  function returnDebt(uint256 amount) public {
    debtIssued[msg.sender] = add(debtIssued[msg.sender], mul(debtIssued[msg.sender], accumulatedRate)); // update balance to include interest
    uint256 issuedDebt = debtIssued[msg.sender];
    require(issuedDebt >= amount, "CDPTracker/exceeds-debt-amount");
    coin = CoinLike(Coin);
    debtIssued[msg.sender] = sub(debtIssued[msg.sender], amount);
    coin.burn(msg.sender, amount);
  }

  function redeemCoins(uint256 amount) public payable {
    coin = CoinLike(Coin);
    require(coin.balanceOf(msg.sender)>=amount, "CDPTracker/exceeds-balance");
    uint256 redemptionRatePerCoin = computeRedeemPrice(Oracle);
    uint256 totalRedemptionAmount = mul(redemptionRatePerCoin, amount)/1000000;
    coin.burn(msg.sender, amount);
    sendRBTC(msg.sender, totalRedemptionAmount);
  }

  function removeCollateral(uint256 amount) public payable {
     require(amount>=dust, 'CDPTracker/non-dusty-collateral-required');
     uint256 _collateral = collateral[msg.sender]; //Amount of RBTC Collateral in CDP
     require(amount<=_collateral, 'CDPTracker/amount-exceeds-deposits');
     uint256 issuedDebt = debtIssued[msg.sender];
     require(issuedDebt==0, 'CDPTracker/debt-not-repaid');
     collateral[msg.sender] = (collateral[msg.sender]) - amount;
     sendRBTC(msg.sender, amount);
   }

   function updateAccumulatedRate(
          address surplusDst,
          int256 rateMultiplier
      ) external isAuthorized {
          accumulatedRate        = add(accumulatedRate, rateMultiplier);
          int256 deltaSurplus                    = mul(globalDebt, rateMultiplier);
          // coinBalance[surplusDst]                = add(coinBalance[surplusDst], deltaSurplus);
          globalDebt                             = add(globalDebt, deltaSurplus);
          emit UpdateAccumulatedRate(
              surplusDst,
              rateMultiplier,
              globalDebt
          );
        }
}
