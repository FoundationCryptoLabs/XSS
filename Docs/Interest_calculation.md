# xBTC stability fee

xBTC utilises a modified version of the accumulated rates mechanism used in DAI/RAI to calculate current surplus, without needing to keep track of historical balances and interest rates. Since there is only one collateral type in xBTC, direct mappings are used instead of "CollateralType" Structs for each collateral used in RAI.

Since collateral ratio is denominated in BTC, there is no risk of liquidation as long as the loan in paid back within the predetermined time limit. The liquidation ratio of the collateral is set to ~115%, which corresponds to a time limit of approximately 3 years for a loan taken out at an average annual interest of 3%.

The CDPTracker stores, an AR (AccumulatedRate) struct that contains the cumulative rate (rate) and the total normalized debt of the system. The TaxCollector stores the per-second rate of interest, that can be updated by governance.


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
