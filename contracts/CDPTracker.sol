pragma solidity 0.6.7;


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

contract CDPTracker {

mapping (address=>uint256) public collateral; // collateral deposited by UserAddress
mapping (address=>uint256) public debtIssued; // debt issued by UserAddress
// mapping (address=>uint256) public interestDue; // interest due by UserAddress
mapping (address=>uint256) public initTime;



address Oracle;
address Coin;
uint256 dust; //Minimum amount of collateral deposited
uint256 Interest; // Interest rate set by governance. Applies from next calculation after rate is set.

uint256 totalDebt;
uint256 totalInterest;
uint256 accumulatedRate;


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
modifier isAuthorized {
    require(authorizedAccounts[msg.sender] == 1, "Coin/account-not-authorized");
    _;
}

// math
function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x);
}
function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x);
}
function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x);
}

function setCoin(address STABLE) external isAuthorized {
  Coin = STABLE;
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
   uint256 currentRedeemPrice = mul(currentBSMA,1000000)/currentBX; //10e3 multiplier to preserve precision of fraction.
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
    uint256 due
    uint256 availableDebt = debtLimit - issuedDebt;
    require(availableDebt >= amount, "CDPTracker/insufficient-collateral-to-mint-stables"); //collateral sufficiency check
    coin = CoinLike(Coin);
    debtIssued[msg.sender] = (debtIssued[msg.sender] + amount);
    totalDebt += amount
    dS= amount*1000000000/totalDebt // post-money share of debt
    DebtShare[msg.sender] += dS
    coin.mint(msg.sender, amount);
  }

  function returnDebt(uint256 amount) public {
    debtIssued[msg.sender] = add(debtIssued[msg.sender], mul(debtIssued[msg.sender], accumulatedRate)); // update balance to include interest
    uint256 issuedDebt = debtIssued[msg.sender];
    require(issuedDebt >= amount, "CDPTracker/exceeds-debt-amount");
    coin = CoinLike(Coin);
    debtIssued[msg.sender] = (debtIssued[msg.sender] - amount);
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
          accumulatedRate        = addition(accumulatedRate, rateMultiplier);
          int256 deltaSurplus                    = multiply(debtAmount, rateMultiplier);
          coinBalance[surplusDst]                = addition(coinBalance[surplusDst], deltaSurplus);
          globalDebt                             = addition(globalDebt, deltaSurplus);
          emit UpdateAccumulatedRate(
              surplusDst,
              rateMultiplier,
              coinBalance[surplusDst],
              globalDebt
          );
        }
}
