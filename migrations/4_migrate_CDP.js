const SafeTracker = artifacts.require("CDPTracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");
const TCol = artifacts.require("TaxCollector");



module.exports = function (deployer) {
  // _CoinAdd = deployer.deploy(Coin, "Zero Volatility BTC","xBTC", "5777");
  // _OracleAdd = deployer.deploy(Oracle);
  //_Oracle ="0x6F86A8ED6576e64DF87E1C52923967e26880a8dC";
  _Coin ="0xeBAE72FAAca0b3a0C2aEF2544aDC4B247bB596F3";
  _Oracle = "0xf16f193d3eD148be21f6D458AAEBF08434435320"
  //_Coin = "0x5F0F963821a05DF5094aA4Ebd12F7803b3B49e95"
  _SafeAdd = deployer.deploy(SafeTracker, _Oracle, 10000);
  // _TaxAdd = deployer.deploy(TCol, "0x4B45A2B43564Ad6372b9FCC4B798979D8852E5aE","0xfC96f45224a898a795570C2CeE868BD2a2F8E6e4");
};
