pragma solidity 0.6.7;

contract CoinLike{
  function addAuthorization(address account) external isAuthorized {}
  function removeAuthorization(address account) external isAuthorized {}
  function transfer(address dst, uint256 amount) external returns (bool) {}
  function transferFrom(address src, address dst, uint256 amount)
        public returns (bool){}
  function mint(address usr, uint256 amount) external isAuthorized {}
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
  function addAuthorization(address account) external isAuthorized {}
  function removeAuthorization(address account) external isAuthorized {}
  function setCollateralRatio(uint256 ratio) external isAuthorized {}
  function peekCollateralRatio() external returns(uint256) {}
  function peekBSMA() external returns(uint256){}
  function peekBX() external returns(uint256){}
}

struct SAFE {
    mapping(address=>uint256) collateral;
    mapping(address=>uint256) debtIssued;
    }

    SAFE[] safes; // list of all SAFE Balances

// Test function; can be decomposed.
function getSafeCollateral(uint256 index) public returns (uint256) {
    SAFE storage safe = safes[index];
    uint256 memory collateral = safe.collateral;
    //
    return collateral;
}

// Test function; can be decomposed.
function getSafeDebt(uint256 index) public returns (uint256) {
  SAFE storage safe = safes[index];
  uint256 memory debtIssued = safe.debtIssued;
  return debtIssued;


address Oracle;
address Coin;
uint256 dust; //Minimum amount of collateral deposited

constructor(address ORC, address STABLE, uint256 DUST){
  Oracle = ORC;
  Coin = STABLE;
  dust = DUST;
}

 function computeDebtLimit(uint256 SafeId, address Oracle) internal returns (uint256){
   Orc = new OracleLike(Oracle);
   //TODO: check safeID exists;
   uint256 collateral = ; //Amount of RBTC Collateral in SAFE
   uint256 currentBSMA = Orc.peekBSMA(); //Current USD redemption rate of 1 xBTC
   uint256 currentCollateralRatio = Orc.peekCollateralRatio(); //12500 by default, to be divided by 100
   uint256 currentDebtLimit = (collateral * currentBSMA) / currentCollateralRatio * 10000 // maximum amount of xBTC that can be minted by a particular safe given current collateral
   return currentDebtLimit;
 }

 function computeRedeemPrice(address Oracle) internal returns (uint256){
   Orc = new OracleLike(Oracle);
   //TODO: check safeID exists;
   uint256 currentSMA = Orc.peekBX(); //BTC-USD exchange rate
   uint256 currentBSMA = Orc.peekBSMA(); //Current USD redemption rate of 1 xBTC
   uint256 currentRedeemPrice = (currentSMA/currentBSMA)*1000000 //10e6 multiplier to preserve precision of fraction
   return currentRedeemPrice;
 }

 function sendRBTC(address payable _to, uint256 amount) internal payable {
        // Call returns a boolean value indicating success or failure.
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        require(sent, "Failed to send RBTC");
    }

 //deposit RBTC collateral in safe
 //use existing safeID or make new safe with lastSAFEID+1
 function depositCollateral(uint256 SafeID) public payable {
    require(msg.value>=dust, 'safeengine/non-dusty-collateral-required');
    // TODO: check SAFEID exists, or create new one via getLastSafeID function.
    // SAFE storage safe = safes[SafeID]; // modularized for clarity
    safes[SafeID].collateral = (safes[SafeID].collateral) + msg.value;
  }

  function takeDebt(uint256 amount, uint256 SafeID) public {
    require(safes[SafeID].address==msg.sender, 'safeengine/safe-not-authorised'); // SAFE only accessible by creator
    //collateral sufficiency check
    // SAFE storage safe = safes[SafeID];
    debtLimit = computeDebtLimit(uint256 SafeID, address Oracle);
    issuedDebt = safes[SafeID].debtIssued;
    availableDebt = debtLimit - issuedDebt;
    require(availableDebt >= amount, "safeengine/insufficient-collateral-to-mint-stables");
    Coin = new CoinLike(coin);
    safes[SafeID].debtIssued = (safes[SafeID].debtIssued + amount)
    Coin.mint(msg.sender, amount);
  }

  function returnDebt(uint256 amount, uint256 SafeID) public {
    require(safes[SafeID].address==msg.sender, 'safeengine/safe-not-authorised');
    issuedDebt = safes[SafeID].debtIssued;
    require(issuedDebt >= amount, "safeengine/exceeds-debt-amount");
    Coin = new CoinLike(coin);
    safes[SafeID].debtIssued = (safes[SafeID].debtIssued - amount)
    Coin.burn(msg.sender, amount);
  }

  function redeemCoins(uint256 amount) public payable {
    Coin = new CoinLike(coin);
    require(Coin.balanceOf(msg.sender)>=amount, "safeengine/exceeds-balance");
    redemptionRatePerCoin = computeRedeemPrice(Orc);
    totalRedemptionAmount = (redemptionRatePerCoin * amount)/1000000;
    Coin.burn(msg.sender, amount);
    sendRBTC(msg.sender, totalRedemptionAmount);
  }

  function removeCollateral(uint256 SafeID, uint256 amount) public payable {
     require(amount>=dust, 'safeengine/non-dusty-collateral-required');
     // TODO: check SAFEID exists.
     uint256 collateral = safes[SafeID].collateral; //Amount of RBTC Collateral in SAFE
     require(amount<=collateral, 'safeengine/amount-exceeds-deposits');
     safes[SafeID].collateral = (safes[SafeID].collateral) - amount;
     sendRBTC(msg.sender, amount);
   }
}
