const SafeTracker = artifacts.require("SafeTracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");


module.exports = function (deployer) {
  // _CoinAdd = deployer.deploy(Coin, "Zero Volatility BTC","xBTC", "5777");
  // _OracleAdd = deployer.deploy(Oracle);
  _Oracle ="0x5921c0C11C3f38EdE7c0B2a35119f8f6ebac4079";
  _Coin ="0x597a0F47572a359410883A58eb001aca990226ec";
  _SafeAdd = deployer.deploy(SafeTracker, _Oracle, _Coin, 10000);
};
