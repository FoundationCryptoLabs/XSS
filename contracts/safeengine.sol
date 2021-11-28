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

contract SafeTracker {

mapping (address=>uint256) public collateral; // collateral deposited by UserAddress
mapping (address=>uint256) public debtIssued; // debt issued by UserAddress

address Oracle;
address Coin;
uint256 dust; //Minimum amount of collateral deposited

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
   //TODO: check safeID exists;
   uint256 _collateral = collateral[msg.sender]; //Amount of RBTC Collateral in SAFE
   uint256 currentBSMA = Orc.peekBSMA(); //Current USD redemption rate of 1 xBTC
   uint256 currentBX = Orc.peekBX();
   // uint256 currentBSMA = 24000;
   uint256 currentCollateralRatio = Orc.peekCollateralRatio(); //12500 by default, to be divided by 100
   // uint256 currentDebtLimit = ((_collateral * currentBSMA ) / currentBX) ; // maximum amount of xBTC that can be minted by a particular safe given current collateral
   uint256 currentDebtLimit = _collateral * currentCollateralRatio; // 1 xBTC can be minted (borrowed) for every 1.25 BTC collateral by default.
   return currentDebtLimit;
 }

 function computeRedeemPrice(address _oracle) internal returns (uint256){
   Orc = OracleLike(_oracle);
   //TODO: check safeID exists;
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
 //use existing safeID or make new safe with lastSAFEID+1
 function depositCollateral() public payable {
    require(msg.value>=dust, 'safeengine/non-dusty-collateral-required');
    // TODO: check SAFEID exists, or create new one via getLastSafeID function.
    // SAFE storage safe = safes[SafeID]; // modularized for clarity
    collateral[msg.sender] = (collateral[msg.sender]) + msg.value;
  }

  function takeDebt(uint256 amount) public {
    //collateral sufficiency check
    // SAFE storage safe = safes[SafeID];
    uint256 debtLimit = computeDebtLimit(Oracle);
    uint256 issuedDebt = debtIssued[msg.sender];
    uint256 availableDebt = debtLimit - issuedDebt;
    require(availableDebt >= amount, "safeengine/insufficient-collateral-to-mint-stables");
    coin = CoinLike(Coin);
    debtIssued[msg.sender] = (debtIssued[msg.sender] + amount);
    coin.mint(msg.sender, amount);
  }

  function returnDebt(uint256 amount) public {
    uint256 issuedDebt = debtIssued[msg.sender];
    require(issuedDebt >= amount, "safeengine/exceeds-debt-amount");
    coin = CoinLike(Coin);
    debtIssued[msg.sender] = (debtIssued[msg.sender] - amount);
    coin.burn(msg.sender, amount);
  }

  function redeemCoins(uint256 amount) public payable {
    coin = CoinLike(Coin);
    require(coin.balanceOf(msg.sender)>=amount, "safeengine/exceeds-balance");
    uint256 redemptionRatePerCoin = computeRedeemPrice(Oracle);
    uint256 totalRedemptionAmount = mul(redemptionRatePerCoin, amount)/1000000;
    coin.burn(msg.sender, amount);
    sendRBTC(msg.sender, totalRedemptionAmount);
  }

  function removeCollateral(uint256 amount) public payable {
     require(amount>=dust, 'safeengine/non-dusty-collateral-required');
     // TODO: check SAFEID exists.
     uint256 _collateral = collateral[msg.sender]; //Amount of RBTC Collateral in SAFE
     require(amount<=_collateral, 'safeengine/amount-exceeds-deposits');
     collateral[msg.sender] = (collateral[msg.sender]) - amount;
     sendRBTC(msg.sender, amount);
   }
}
