const SafeTracker = artifacts.require("CDPtracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");

web3=require('web3')

//RSK Testnet Deployed Addresses:
_Oracle ="0x6396d118a1B4442ccC9a1644E3ADA3474eE9b087";
_Coin ="0xE98e8cE36012e27b806090FDa87eC04b8f078803";

//_Oracle="0x29e30dC86578E336a0930012315aed2d398802b4"
//locally deployed addresses (please change these after running truffle migrate --network=dev)
// _Oracle ="0xD2D9Ae45A4df94CA4c921F65cb8Ece0f968140f5";
// _Coin ="0xc3dDD87D860C7b2b5e11F57026B603D1684DAeEB";
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
it("Deposit 0.0125 rbtc, mint 0.01 xBTC debt, attempt to withdraw 0.0125 btc, FAILS [[expected error: CDPTracker/debt-not-repaid]]", async function () {
        const safe_ = await SafeTracker.new(_Oracle, 10000);
        await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.0225", "ether")});
        // add safe to coin
        // const coin_ = Coin.at("0x597a0F47572a359410883A58eb001aca990226ec");
        console.log(safe_.address);
        const coin_ = await Coin.new("XBTC", "XBTC", "5777");
        await coin_.addAuthorization(safe_.address);
        await safe_.setCoin(coin_.address);
        await safe_.takeDebt(web3.utils.toWei("0.010", "ether"));
        // assert.equal(await safe_.debtIssued(accounts[0]), web3.utils.toWei("0.010", "ether"));
        await safe_.removeCollateral(web3.utils.toWei("0.009", "ether")); // FAILS
      });





});
