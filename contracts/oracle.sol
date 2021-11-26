pragma solidity 0.6.7


contract Orc {
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

  event AddAuthorization(address account);
  event RemoveAuthorization(address account);
  event Approval(address indexed src, address indexed guy, uint256 amount);

  constructor() public {
    emit AddAuthorization(msg.sender);
  }

  // Default Collateral Ratio of 125%
  uint256 collateralRatio = 12500;
  function setCollateralRatio(uint256 ratio) external isAuthorized {
      collateralRatio = ratio;
  }

  function peekCollateralRatio() external returns(uint256) {
    return collateralRatio;
  }

  // Returns current 4 year SMA for BTC/USD. FIXME: Template Function used.
  function peekBSMA() external returns(uint256){
    uint256 block = block.number;
    if (block%2==0){
      uint256 BSMA = 22000;
    }
    else {
      uint256 BSMA = 24000;
    }
    return BSMA;
  }

// Returns current BTC/USD exchange rate. FIXME: Template Function used.
  function peekBX() external returns(uint256){
    uint256 block = block.number;
    if (block%2==0){
      uint256 BX = 56000;
    }
    else {
      uint256 BX = 62000;
    }
    return BX;
  }
}
