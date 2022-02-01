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
    function newAR(uint256 newRATE) external {
    }

    // Function called by TaxCollector Contract
    function updateGlobalDebt(uint256 newDebt) external {
    }

    // Function called by TaxCollector Contract
    function issueSurplus(uint256 amount, address treasury) external {
      }
    function updateAccumulatedRate(bytes32,address,int256) virtual external;
    function coinBalance(address) virtual public view returns (uint256);
    uint256 public globalDebt;
    uint256 public totalSurplus;
    uint256 public lastAR;
    uint256 public INIT;
}



contract TaxCollector is DSMath {
    uint256 RATE = 100000564701133626865910626; //[ray] per second rate, 5% per day
    uint256 globalStabilityFee= 100000564701133626865910626; //current per second interestDue rate
    address public Treasury;
    CDPlike CDP;

    //AR : Rate Accumulator
    struct AR {
      uint256 updateTime;
      uint128 RATE; // [ray]
    }

    AR RateAccumulator;

    constructor(address CDPcontract, address TreasuryContract) public {
       CDP = CDPlike(CDPcontract);
       Treasury = TreasuryContract;
       RateAccumulator.RATE= 1*10**27;
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

    // interest per second ^ N
  function updateAccumulatedRate() public returns (uint128) {
    uint128 lastRate = RateAccumulator.RATE;
    if (now <= RateAccumulator.updateTime) {
    uint64 powertime = 86406; // set to 1 day by default. replace with time gap since last update using
    uint256 initTime = CDP.INIT();
    //uint64 powertime = block.timestamp - initTime;
    uint256 rateupdate = rpow(globalStabilityFee, powertime);
    uint256 globalDebt = CDP.globalDebt();
    uint256 globalLastAR = CDP.lastAR();
    uint256 newDebt = rmul(rdiv(lastRate, globalLastAR), globalDebt); // surplus since last update.
    RateAccumulator.RATE=uint128(rateupdate);
    CDP.newAR(rateupdate);
    CDP.updateGlobalDebt(newDebt);
    uint256 surplus = newDebt - globalDebt;
    // surplus is minted at the time of calculation, all funds including interest are burnt when debt is repaid.
    if(surplus>0){
      CDP.issueSurplus(surplus, Treasury);
  }
    return RateAccumulator.RATE;
    }
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
