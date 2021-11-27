const SafeTracker = artifacts.require("SafeTracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");

web3=require('web3')

_Oracle ="0x87ad8BB8d6723596F89F7C2A73609483C2Fa109F";
_Coin ="0x597a0F47572a359410883A58eb001aca990226ec";


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

contract("Coin", (accounts) => {
  it("peekCollateralRatio, peekBSMA, peekBX", async function () {
    const coin_ = await Coin.new('stable BTC', 'xBTC', "5777");
    const march = await orc_.peekCollateralRatio.call()
    assert.equal(march , 12500);
});
});

contract("SafeTracker", (accounts) => {
  it("Deposit 2 ether, check collateral balance", async function () {
    const safe_ = await SafeTracker.new(_Oracle, 10000);
    await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.2", "ether")})
    assert.equal(await safe_.collateral(accounts[0]), web3.utils.toWei("0.2", "ether"));
      });

  it("Deposit 2 ether, Withdraw 1 ether, check collateral balance is 1 ether", async function () {
      const safe_ = await SafeTracker.new(_Oracle, 10000);
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.2", "ether")});
      await safe_.removeCollateral(web3.utils.toWei("0.1", "ether"));
      assert.equal(await safe_.collateral(accounts[0]), web3.utils.toWei("0.1", "ether"));
  });

  it("Deposit 3 btc, mint 2 xBTC debt, check debtIssued", async function () {
      const safe_ = await SafeTracker.new(_Oracle, 10000);
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.3", "ether")});
      //add safe to coin
      //const coin_ = Coin.at("0x597a0F47572a359410883A58eb001aca990226ec");
      console.log(safe_.address);
      const coin_ = await Coin.new("XBTC", "XBTC", "5777");
      await coin_.addAuthorization(safe_.address);
      await safe_.setCoin(coin_.address);
      await safe_.takeDebt(web3.utils.toWei("0.005", "ether"));
      assert.equal(await safe_.debtIssued(accounts[0]), web3.utils.toWei("0.005", "ether"));
});
});
