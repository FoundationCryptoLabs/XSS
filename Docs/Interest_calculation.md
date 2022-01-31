# xBTC stability fee

xBTC utilises a modified version of the accumulated rates mechanism used in DAI/RAI to calculate current surplus, without needing to keep track of historical balances and interest rates. Since there is only one collateral type in xBTC, direct mappings are used instead of "CollateralType" Structs for each collateral used in RAI.

Since collateral ratio is denominated in BTC, there is no risk of liquidation as long as the loan in paid back within the predetermined time limit. The liquidation ratio of the collateral is set to ~115%, which corresponds to a time limit of approximately 3 years for a loan taken out at an average annual interest of 3%.

The CDPTracker stores, an AR (AccumulatedRate) struct that contains the cumulative rate (rate) and the total normalized debt of the system. The TaxCollector stores the per-second rate of interest, that can be updated by governance.

Calling Tax.updateAR() computes an update to the AR based on the per second interest rate, and the time since drip was last called for the given ilk (rho).
Then the Jug invokes Vat.fold(bytes32 ilk, address vow, int rate_change) which:
adds rate_change to rate for the specified ilk.
The next step is to calculate a user's specific interest dues. To do this, the CDPTracker contract has the function.
increases the Vow's surplus by Art*rate_change
increases the system's total debt (i.e. issued Dai) by Art*rate_change.
Each individual Vault (represented by an Urn struct in the Vat) stores a "normalized debt" parameter called art. Any time it is needed by the code, the Vault's total debt, including stability fees, can be calculated as art*rate (where rate corresponds to that of the appropriate collateral type). Thus an update to Ilk.rate via Jug.drip(bytes32 ilk) effectively updates the debt for all Vaults collateralized with ilk tokens.




Number Types
XSS uses different numbers representing various levels of precision.
Type
Precision
Wad
1E-18
Ray
1E-27
Rad
1E-45
Operations: Addition, Subtraction, Division

Wad, Ray, and Rad can only perform addition, subtraction and division with another Wad, Ray, or Rad


Key Differences from GEB

All references to CollateralType have been removed, as only one collateral type, RBTC is permitted. In particular, the following struct -
`struct CollateralType {
    uint256 stabilityFee;
    uint256 updateTime;
}`
Has been replaced with single global variables, `globalStabilityFee` and `globalUpdateTime`.
Similarly, there is no secondary 'duty' variable for each collateral type that is addeed to the stability fee.


Similarly, a single tax reciever has to be selected, rather than various taxRecievers for each collateral type used in GEB. This tax reciever will be the DAO treasury contract. Subsequently, the surplus funds collected in the DAO treasury may be utilised however the DAO votes to spend them.
