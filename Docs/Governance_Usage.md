# EVI Governor

Three contracts handle the governance process:
1. Governor.sol : This snapshots EVI token balances for voting, allows a proposal to be created, and then voted upon after a specified timelock. Based on the Governor template from openzepplin.
2. GovToken.sol : This is the contract for the EVI token. Based on the ERC20Votes template from openzepplin, this is used by the Governor contract to determine the voting power of each address for purposes of voting.
3. Executor.sol : This contract is called by governor whenever a particular proposal is approved - it has the permissions to modify interest rate in the CDPTracker, or disburse funds from the Treasury, as the case may be.
