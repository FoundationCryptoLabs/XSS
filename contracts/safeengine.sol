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


 struct safe {
   mapping(address=>uint256) safeID
 }

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
   uint256 collateral = safes[SafeID].collateral(); //Amount of RBTC Collateral in SAFE
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
   uint256 currentRedeemPrice = (currentSMA/currentBSMA)*1000000 //1M multiplier to preserve precision of fraction
   return currentRedeemPrice;
 }

 function sendRBTC(address payable _to, uint256 amount) internal payable {
        // Call returns a boolean value indicating success or failure.
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

 //deposit RBTC collateral in safe
 //use existing safeID or make new safe with lastSAFEID+1
 //TODO: add reciever fallback function to accept native RBTC.
 function depositCollateral(uint256 SafeID) public {
    require(msg.value>=dust, 'safeengine/non-dusty-collateral-required');
    // TODO: check SAFEID exists, or create new one via getLastSafeID function.
    safe[SafeID].collateral = (safe[SafeID].collateral) + msg.value;
  }

  function takeDebt(uint256 amount, uint256 SafeID) public {
    require(safe[SafeID].address==msg.sender, 'safeengine/safe-not-authorised'); // SAFE only accessible by creator
    //collateral sufficiency check
    debtLimit = computeDebtLimit(uint256 SafeID, address Oracle);
    issuedDebt = safe[SafeID].debtIssued;
    availableDebt = debtLimit - issuedDebt;
    require(availableDebt >= amount, "safeengine/insufficient-collateral-to-mint-stables");
    Coin = new CoinLike(coin);
    safe[SafeID].debtIssued = (safe[SafeID].debtIssued + amount)
    Coin.mint(msg.sender, amount);
  }

  function returnDebt(uint256 amount, uint256 SafeID) public {
    require(safe[SafeID].address==msg.sender, 'safeengine/safe-not-authorised');
    issuedDebt = safe[SafeID].debtIssued;
    require(issuedDebt >= amount, "safeengine/exceeds-debt-amount");
    Coin = new CoinLike(coin);
    safe[SafeID].debtIssued = (safe[SafeID].debtIssued - amount)
    Coin.burn(msg.sender, amount);
  }

  function redeemCoins(uint256 amount) public {
    Coin = new CoinLike(coin);
    require(Coin.balanceOf(msg.sender)>=amount, "safeengine/exceeds-balance");
    redemptionRatePerCoin = computeRedeemPrice(Orc);
    totalRedemptionAmount = (redemptionRatePerCoin * amount)/1000000;
    Coin.burn(msg.sender, amount);
    sendRBTC(msg.sender, totalRedemptionAmount);
  }

  function removeCollateral()

}
