


// calculate interest between start and end blocks for address X
// this needs to be called any time there is either-
// A rate change by governance
// A collateralisation change either by takedebt or returnDebt functions
// An incident of repayment

pragma solidity 0.6.7;

import "../shared/LinkedList.sol";

abstract contract CDPlike {
    function collateralData() virtual public view returns (
        uint256 debtAmount,       // [wad]
        uint256 accumulatedRate   // [ray]
    );
    function updateAccumulatedRate(bytes32,address,int256) virtual external;
    function coinBalance(address) virtual public view returns (uint256);
    function SafeData(address) virtual public view returns (
      uint256 accumulatedDebt,
      uint256 lastRate
    )
    function RateData() virtual public view returns (
      uint256 accumulatedRate,
      uint256 updateTime
    )
}



contract TaxCollector {
    using LinkedList for LinkedList.List;
    // uint256 updateTime;
    uint256 globalStabilityFee; //current per second interestDue rate
    address public primaryTaxReceiver;

    struct AR {
      uint256 updateTime
      uint256 accumulatedRate
    }

    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */

     SAFEEngineLike public safeEngine;

     // --- Init ---
     constructor(address safeEngine_) public {
         authorizedAccounts[msg.sender] = 1;
         safeEngine = SAFEEngineLike(safeEngine_);
         emit AddAuthorization(msg.sender);
     }

     //Math
     // --- Math ---
     uint256 public constant RAY           = 10 ** 27;
     uint256 public constant WHOLE_TAX_CUT = 10 ** 29;
     uint256 public constant ONE           = 1;
     int256  public constant INT256_MIN    = -2**255;

     function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
       assembly {
         switch x case 0 {switch n case 0 {z := b} default {z := 0}}
         default {
           switch mod(n, 2) case 0 { z := b } default { z := x }
           let half := div(b, 2)  // for rounding.
           for { n := div(n, 2) } n { n := div(n,2) } {
             let xx := mul(x, x)
             if iszero(eq(div(xx, x), x)) { revert(0,0) }
             let xxRound := add(xx, half)
             if lt(xxRound, xx) { revert(0,0) }
             x := div(xxRound, b)
             if mod(n,2) {
               let zx := mul(z, x)
               if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
               let zxRound := add(zx, half)
               if lt(zxRound, zx) { revert(0,0) }
               z := div(zxRound, b)
             }
           }
         }
       }
     }

     function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
         z = x + y;
         require(z >= x, "TaxCollector/add-uint-uint-overflow");
     }
     function addition(int256 x, int256 y) internal pure returns (int256 z) {
         z = x + y;
         if (y <= 0) require(z <= x, "TaxCollector/add-int-int-underflow");
         if (y  > 0) require(z > x, "TaxCollector/add-int-int-overflow");
     }
     function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
         require((z = x - y) <= x, "TaxCollector/sub-uint-uint-underflow");
     }
     function subtract(int256 x, int256 y) internal pure returns (int256 z) {
         z = x - y;
         require(y <= 0 || z <= x, "TaxCollector/sub-int-int-underflow");
         require(y >= 0 || z >= x, "TaxCollector/sub-int-int-overflow");
     }
     function deduct(uint256 x, uint256 y) internal pure returns (int256 z) {
         z = int256(x) - int256(y);
         require(int256(x) >= 0 && int256(y) >= 0, "TaxCollector/ded-invalid-numbers");
     }
     function multiply(uint256 x, int256 y) internal pure returns (int256 z) {
         z = int256(x) * y;
         require(int256(x) >= 0, "TaxCollector/mul-uint-int-invalid-x");
         require(y == 0 || z / y == int256(x), "TaxCollector/mul-uint-int-overflow");
     }
     function multiply(int256 x, int256 y) internal pure returns (int256 z) {
         require(!both(x == -1, y == INT256_MIN), "TaxCollector/mul-int-int-overflow");
         require(y == 0 || (z = x * y) / y == x, "TaxCollector/mul-int-int-invalid");
     }
     function rmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
         z = x * y;
         require(y == 0 || z / y == x, "TaxCollector/rmul-overflow");
         z = z / RAY;
     }

     // --- Boolean Logic ---
     function both(bool x, bool y) internal pure returns (bool z) {
         assembly{ z := and(x, y)}
     }
     function either(bool x, bool y) internal pure returns (bool z) {
         assembly{ z := or(x, y)}
     }


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
        require(authorizedAccounts[msg.sender] == 1, "TaxCollector/account-not-authorized");
        _;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);

    // interest per second ^ N
    function taxSingleOutcome() public view returns (uint256, int256) {
      uint256 lastAccumulatedRate = CDP.accumulatedRate();
      uint256 newlyAccumulatedRate =
        rmultiply(
          rpow(
              globalStabilityFee,     // Only one collateral type.
            subtract(
              now,
              updateTime
            ),
          RAY),
        lastAccumulatedRate);
      return (newlyAccumulatedRate, deduct(newlyAccumulatedRate, lastAccumulatedRate));
      }

    function taxSingle(bytes32 collateralType) public returns (uint256) {
          uint256 latestAccumulatedRate;
          if (now <= updateTime) {
            (, latestAccumulatedRate) = CDP.accumulatedRate();
            return latestAccumulatedRate;
          }
          (uint256 latestAccumulatedRate, int256 deltaRate) = taxSingleOutcome();
          // Check how much debt has been generated for collateralType
          (uint256 debtAmount, ) = CDP.debtAmount(); //globalDebt
          distributeTax(debtAmount, deltaRate);
          updateTime = now;
          emit CollectTax(latestAccumulatedRate, deltaRate);
          return latestAccumulatedRate;
      }


      function changeInterest(uint256 newRate) public isAuthorized returns (bool) {
        uint256 currentAR = updateAR(); // update AR based on old interest till current block
        globalStabilityFee = newRate ; // update interest rate per second
      }


      function updateAR() public returns (uint256) {
        if (now <= updateTime) {
          (, latestAccumulatedRate) = CDP.accumulatedRate();
          return latestAccumulatedRate;

        (uint256 latestAccumulatedRate, int256 deltaRate) = taxSingleOutcome();  // calculate latest AR, save it
        // Check how much debt has been generated
        (uint256 debtAmount, ) = CDP.globalDebt(); //globalDebt
        // distribute Delta tax to treasury
        AR.accumulatedRate = latestAccumulatedRate; //update the Structs
        AR.updateTime = now;
        distributeTax(debtAmount, deltaRate);
        // updateTime = now;
        emit CollectTax(latestAccumulatedRate, deltaRate);
        return latestAccumulatedRate;
      }

      function giveTax(address user) internal {
        uint256 surplus = CDP.safes[user].accumulatedDebt - CDP.safes[user].generatedDebt
        
      }
      function distributeTax(
          address receiver,
          uint256 debtAmount,
          int256 deltaRate
      ) internal {
          require(CDP.coinBalance(receiver) < 2**255, "TaxCollector/coin-balance-does-not-fit-into-int256");
          // Check how many coins the receiver has and negate the value
          int256 coinBalance   = -int256(safeEngine.coinBalance(receiver));
          // Compute the % out of SF that should be allocated to the receiver
          require(receiver == primaryTaxReceiver, 'reciever not authorized'); //permits only one reciever - i.e. treasury contract.
          int256 currentTaxCut = multiply(subtract(WHOLE_TAX_CUT, deltaRate) / int256(WHOLE_TAX_CUT) :
          /**
              If SF is negative and a tax receiver doesn't have enough coins to absorb the loss,
              compute a new tax cut that can be absorbed
          **/
          currentTaxCut  = (
            both(multiply(debtAmount, currentTaxCut) < 0, coinBalance > multiply(debtAmount, currentTaxCut))
          ) ? coinBalance / int256(debtAmount) : currentTaxCut;
          /**
            If the tax receiver's tax cut is not null and if the receiver accepts negative SF
            offer/take SF to/from them
          **/
          if (currentTaxCut != 0) {
            if (
              either(
                receiver == primaryTaxReceiver,
                either(
                  deltaRate >= 0,
                  both(currentTaxCut < 0, secondaryTaxReceivers[collateralType][receiverListPosition].canTakeBackTax > 0)
                )
              )
            ) {
              CDP.updateAccumulatedRate(receiver, currentTaxCut);
              emit DistributeTax(receiver, currentTaxCut);
            }
         }
}
