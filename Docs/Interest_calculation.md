# xBTC stability fee

xBTC utilises the accumulated rates mechanism used in MCD/FLX to calculate current surplus,
without needing to keep track of historical balances and interest rates. Since there is only one collateral type in xBTC,
singular mappings are used instead of "CollateralType" Structs for each collateral used in RAI.

Since cottateral ratio is denominated in BTC, there is no risk of liquidation as long as the loan in paid back within the predetermined time limit. The liquidation ratio of the collateral is set to ~115%, which corresponds to a time limit of approximately 3 years for a loan taken out at an average annual interest of 3%.

function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x);
}
function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x);
}
function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x);
}
function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "SAFEEngine/multiply-uint-uint-overflow");
}



function add(uint256 x, int256 y) internal pure returns (uint256 z) {
    z = x + uint256(y);
    require(y >= 0 || z <= x, "SAFEEngine/add-uint-int-overflow");
    require(y <= 0 || z >= x, "SAFEEngine/add-uint-int-underflow");
}
function add(int256 x, int256 y) internal pure returns (int256 z) {
    z = x + y;
    require(y >= 0 || z <= x, "SAFEEngine/add-int-int-overflow");
    require(y <= 0 || z >= x, "SAFEEngine/add-int-int-underflow");
}
function sub(uint256 x, int256 y) internal pure returns (uint256 z) {
    z = x - uint256(y);
    require(y <= 0 || z <= x, "SAFEEngine/sub-uint-int-overflow");
    require(y >= 0 || z >= x, "SAFEEngine/sub-uint-int-underflow");
}
function sub(int256 x, int256 y) internal pure returns (int256 z) {
    z = x - y;
    require(y <= 0 || z <= x, "SAFEEngine/sub-int-int-overflow");
    require(y >= 0 || z >= x, "SAFEEngine/sub-int-int-underflow");
}
function mul(uint256 x, int256 y) internal pure returns (int256 z) {
    z = int256(x) * y;
    require(int256(x) >= 0, "SAFEEngine/mul-uint-int-null-x");
    require(y == 0 || z / y == int256(x), "SAFEEngine/mul-uint-int-overflow");
}
function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x);
}

function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "SAFEEngine/add-uint-uint-overflow");
}
function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "SAFEEngine/sub-uint-uint-underflow");
}
