pragma solidity 0.6.7;

contract CoinLike{
function addAuthorization(address account) external isAuthorized {}
function removeAuthorization(address account) external isAuthorized {}
function transfer(address dst, uint256 amount) external returns (bool) {}
unction transferFrom(address src, address dst, uint256 amount)
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

}

contract SafeEngine {


 struct safe {
   mapping(address=>uint256) safeID
 }

address Oracle;
address Coin;
address Vat;

constructor(address ORC, address STABLE){
  Oracle = ORC;
  Coin = STABLE;
}

 function computeDebtLimit(uint256 SafeId, address Oracle) internal return(uint256){
   Orc = new OracleLike(Oracle);
   collateral = safes[SafeID].collateral();
   // currentSMA = Orc.peekSMA(); //USD value of redemption rate
   uint256 currentBSMA = Orc.peekBSMA(); //Percentage of BTC value of redemption rate for 1 xBTC, to be divided by 100
   uint256 currentCollateralRatio = Orc.peekCollateralRatio(); //12500 by default, to be divided by 100
   uint256 currentDebtLimit = (collateral * currentBSMA) / currentCollateralRatio * 10000 // maximum amount of xBTC that can be minted by a particular safe given current collateral
   return currentDebtLimit;
 }

 function sendRBTC(address payable _to, uint256 amount) internal payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

 //deposit RBTC collateral in safe
 //use existing safeID or make new safe with lastSAFEID+1
 function depositCollateral(uint256 SafeID) public {
    require(msg.value>=dust, 'safeengine/non-dusty-collateral-required');
    safe[SafeID].collateral = (safe[SafeID].collateral) + msg.value;


  }

  function takeDebt(uint256 amount, uint256 SafeID) public {
    require(safe[SafeID].address==msg.sender, 'safeengine/safe-not-authorised');
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
    Orc = new OracleLike(Oracle);
    redemptionRatePerCoin = Orc.peekBSMA();
    totalRedemptionAmount = redemptionRatePerCoin * amount;
    Coin.burn(msg.sender, amount);
    sendRBTC(msg.sender, amount);
  }

}
