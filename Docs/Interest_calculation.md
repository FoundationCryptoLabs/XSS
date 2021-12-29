# xBTC stability fee

xBTC utilises the accumulated rates mechanism used in MCD/FLX to calculate current surplus,
without needing to keep track of historical balances and interest rates. Since there is only one collateral type in xBTC,
singular mappings are used instead of "CollateralType" Structs for each collateral used in RAI.
