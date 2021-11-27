const SafeTracker = artifacts.require("SafeTracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");


module.exports = function (deployer) {
  // _CoinAdd = deployer.deploy(Coin, "Zero Volatility BTC","xBTC", "5777");
  // _OracleAdd = deployer.deploy(Oracle);
  _Oracle ="0x87ad8BB8d6723596F89F7C2A73609483C2Fa109F";
  _Coin ="0x597a0F47572a359410883A58eb001aca990226ec";
  _SafeAdd = deployer.deploy(SafeTracker, _Oracle, 10000);
};
