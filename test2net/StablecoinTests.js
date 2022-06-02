const SafeTracker = artifacts.require("CDPtracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");

web3=require('web3')



//_Oracle="0x29e30dC86578E336a0930012315aed2d398802b4"
//locally deployed addresses (please change these after running truffle migrate --network=dev)
//_Oracle ="0x6f866e57B012e9E682906842c2129fddD664eDA1";
//_Coin ="0x53A050dEa87F8A56c70705ba2dcA19d04e7177ac";

//_Oracle = "0x60F1a423D19C76D4ce585a0A3133072E8b2Ce015"
//_Coin = "0x5F0F963821a05DF5094aA4Ebd12F7803b3B49e95"

//contractcdp = 0x898c1C26D21DD8E85c34bfb57CBf51CB796eBaf9;

_Coin ="0xeBAE72FAAca0b3a0C2aEF2544aDC4B247bB596F3";
_Oracle = "0xf16f193d3eD148be21f6D458AAEBF08434435320"
//RSK Testnet Deployed Addresses:
//_Oracle ="0x2Ef2757bD2c469a7F8afa251f17700aaa6B9F3B7";
//_Coin ="0x3bf9e5bb65c580fbe1936bd7edd60aaad4f38eb0";

contract("Oracle", (accounts) => {
  it("peekCollateralRatio, peekBSMA, peekBX", async function () {
    const orc_ = await Oracle.new();
    const march = await orc_.peekCollateralRatio.call()
    assert.equal(march , 12500);
});

    it("peekBX", async function () {
    const orc_ = await Oracle.new();
    const march2 = await orc_.peekBX.call()
    assert.equal(march2 , 60000);

});
    it("peekBSMA", async function () {
    const orc_ = await Oracle.new();
    const march2 = await orc_.peekBSMA.call()
    assert.equal(march2 , 20000);
});
});


contract("SafeTracker", (accounts) => {
  // Test Debt issuance based on the rules of the protocol


// Change values to 0.0125 btc, 0.01 btc and so on for RSK TESTNET.
it("[[redeemCoins]] Deposit 12.5 rbtc, mint 10 xBTC debt, transfer 9 xBTC to accounts[1], redeem 8 xBTC for RBTC, check remaining balance = 1 xBTC.", async function () {
    const safe_ = await SafeTracker.new(_Oracle, 10000);
    await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("12.5", "ether")});
    //add safe to coin
    //const coin_ = Coin.at("0x597a0F47572a359410883A58eb001aca990226ec");
    console.log(safe_.address);
    const coin_ = await Coin.new("XBTC", "XBTC", "5777");
    await coin_.addAuthorization(safe_.address);
    await safe_.setCoin(coin_.address);
    await safe_.takeDebt(web3.utils.toWei("10", "ether"));
    // assert.equal(await safe_.debtIssued(accounts[0]), web3.utils.toWei("0.10", "ether"));
    await coin_.transfer(accounts[1], web3.utils.toWei("9", "ether"));
    // assert.equal(coin_.balanceOf(accounts[1], web3.utils.toWei("0.9", "ether")));
    await safe_.redeemCoins(web3.utils.toWei("8", "ether"), {from:accounts[1]});
    const bn_balance = await coin_.balanceOf.call(accounts[1]);
    const num_balance = BigInt(bn_balance);
    assert.equal(num_balance, web3.utils.toWei("1", "ether"));
});

it("Deposit 0.125 rbtc, mint 0.1 xBTC debt, attempt to withdraw 0.125 btc, FAILS [[expected error: CDPTracker/debt-not-repaid]]", async function () {
      const safe_ = await SafeTracker.new(_Oracle, 10000);
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.125", "ether")});
      //add safe to coin
      //const coin_ = Coin.at("0x597a0F47572a359410883A58eb001aca990226ec");
      console.log(safe_.address);
      const coin_ = await Coin.new("XBTC", "XBTC", "5777");
      await coin_.addAuthorization(safe_.address);
      await safe_.setCoin(coin_.address);
      await safe_.takeDebt(web3.utils.toWei("0.10", "ether"));
      await safe_.removeCollateral(web3.utils.toWei("0.009", "ether"));
    });




});
