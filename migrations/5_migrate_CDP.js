const SafeTracker = artifacts.require("CDPTracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");


module.exports = function (deployer) {
  // _CoinAdd = deployer.deploy(Coin, "Zero Volatility BTC","xBTC", "5777");
  // _OracleAdd = deployer.deploy(Oracle);
  _Oracle ="0x6F86A8ED6576e64DF87E1C52923967e26880a8dC";
  _Coin ="0x67ead23FCa16bDC4321d00b4504BfbA3AcE22A93";
  _SafeAdd = deployer.deploy(SafeTracker, _Oracle, 10000);
};
