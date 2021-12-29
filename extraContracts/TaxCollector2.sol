


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
}



contract TaxCollector {
    using LinkedList for LinkedList.List;

    // --- Auth ---
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
          if (now <= collateralTypes[collateralType].updateTime) {
            (, latestAccumulatedRate) = CDP.accumulatedRate();
            return latestAccumulatedRate;
          }
          (, int256 deltaRate) = taxSingleOutcome();
          // Check how much debt has been generated for collateralType
          (uint256 debtAmount, ) = CDP.debtAmount(); //globalDebt
          splitTaxIncome(collateralType, debtAmount, deltaRate);
          latestAccumulatedRate = CDP.accumulatedRate();
          updateTime = now;
          emit CollectTax(latestAccumulatedRate, deltaRate);
          return latestAccumulatedRate;
      }

      function splitTaxIncome(bytes32 collateralType, uint256 debtAmount, int256 deltaRate) internal {
          // Distribute to primary receiver
          distributeTax(collateralType, primaryTaxReceiver, uint256(-1), debtAmount, deltaRate);
      }

      function distributeTax(
          address receiver,
          uint256 debtAmount,
          int256 deltaRate
      ) internal {
          require(safeEngine.coinBalance(receiver) < 2**255, "TaxCollector/coin-balance-does-not-fit-into-int256");
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


    function calculate_interest(uint256 start, uint256 end, address userAddress) public {
      require(CDP.getLastUpdate(userAddress)==start, 'interest double calculation')
      re
      userDebt = CDP.getuserDebt(userAddress);
      for(i=0, i<(end-start), i++){
      BlockRate = CDP.getRate();
      interest = userDebt * BlockRate
      userDebt = userDebt + interest
      }
      CDP.setUserDebt(userDebt); // set user debt to new debt
      CDP.setLastUpdate()
      }


      //move to cdp
