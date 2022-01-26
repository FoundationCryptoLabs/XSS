// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

import "./dsmath.sol";

abstract contract CDPlike {
    function collateralData() virtual public view returns (
        uint256 debtAmount,       // [wad]
        uint256 accumulatedRate   // [ray]
    );
    function updateAccumulatedRate(bytes32,address,int256) virtual external;
    function coinBalance(address) virtual public view returns (uint256);
}



contract TaxCollector is DSMath {
    uint256 RATE = 100000000015815; // per second rate
    uint256 ACCRATE;
    uint256 AccruedDebt;
    uint256 globalStabilityFee; //current per second interestDue rate
    address public primaryTaxReceiver;
    CDPlike CDP;

    constructor(address CDPcontract) public {
       CDP = CDPlike(CDPcontract);
    }

    //AR : Rate Accumulator
    struct AR {
      uint256 updateTime;
      uint256 accumulatedRate; // [ray]
    }

    AR RateAccumulator;

    // interest per second ^ N
    function taxSingleOutcome() internal view returns (uint256, uint256) {
      (, uint256 lastAccumulatedRate) = CDP.collateralData();
      uint256 newlyAccumulatedRate =
        rmul(
          rpow(
              globalStabilityFee,     // Only one collateral type.
            sub1(
              now,
              RateAccumulator.updateTime
            )
          ),
        lastAccumulatedRate);
      return (newlyAccumulatedRate, sub1(newlyAccumulatedRate, lastAccumulatedRate));
      }

    function updateAR() public returns (uint256) {
      if (now <= RateAccumulator.updateTime) {
        (, uint256 latestAccumulatedRate) = CDP.collateralData();
        return latestAccumulatedRate;
      }
      (uint256 latestAccumulatedRate, uint256 deltaRate) = taxSingleOutcome();  // calculate latest AR, save it
      // Check how much debt has been generated
      (uint256 debtAmount, ) = CDP.collateralData(); //globalDebt
      // distribute Delta tax to treasury
      RateAccumulator.accumulatedRate = latestAccumulatedRate; //update the Structs
      RateAccumulator.updateTime = now;
      uint256 GeneratedDebt = debtAmount;
      uint256 surplus = AccruedDebt - GeneratedDebt;
      distributeTax(primaryTaxReceiver, debtAmount, surplus);
      AccruedDebt -= surplus;

      // updateTime = now;
      // emit CollectTax(latestAccumulatedRate, deltaRate);
      return latestAccumulatedRate;
    }

      function changeInterest(uint256 newRate) public isAuthorized returns (bool) {
        uint256 currentAR = updateAR(); // [ray] update AR based on old interest till current block
        globalStabilityFee = newRate ; // [ray]  update interest rate per second
      }

      function distributeTax(
          address receiver,
          uint256 debtAmount,
          uint256 surplusAmount
      ) internal {
          require(CDP.coinBalance(receiver) < 2**255, "TaxCollector/coin-balance-does-not-fit-into-int256");
          // Check how many coins the receiver has and negate the value
          // int256 coinBalance   = -int256(CDP.coinBalance(receiver));
          // add to cumulative ticker of interest issued.
          // CDP.updateIssuedInterest(receiver, surplusAmount);
          //transfer Coins to Treasury
          // Treasury.transfer(receiver, surplusAmount);
          // emit DistributeTax(receiver, surplusAmount);
        }

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
    // event InitializeCollateralType(bytes32 collateralType);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event ModifyParameters(
      uint256 position,
      uint256 val
    );
    event ModifyParameters(
      uint256 position,
      uint256 taxPercentage,
      address receiverAccount
    );
    event CollectTax(bytes32 indexed collateralType, uint256 latestAccumulatedRate, int256 deltaRate);
    event DistributeTax(bytes32 indexed collateralType, address indexed target, int256 taxCut);
}
