const SafeTracker = artifacts.require("SafeTracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");


module.exports = function (deployer) {
  _CoinAdd = deployer.deploy(Coin, "Stable BTC","xBTC", "31"); //configure for RSK testnet
  // _OracleAdd = deployer.deploy(Oracle);
};
