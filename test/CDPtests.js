const SafeTracker = artifacts.require("SafeTracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");

web3=require('web3')

//RSK Testnet Deployed Addresses:
_Oracle ="0x6fAF06e91a6aDB799d6211551fA09BB276a4c5E3";
_Coin ="0x53c7eC0675885769a01E0FA351af0b3E61E8FE07";

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
});

contract("SafeTracker", (accounts) => {
  // web3.eth.getBalance(accounts[0], (err, res) => console.log (res))

  // Test opening a CDP position by depositing Collateral
  it("Deposit 0.02 RBTC, check collateral balance [[depositCollateral]]", async function () {
      //await web3.eth.sendTransaction({to:accounts[0], from:accounts[1], value:web3.utils.toWei('30', 'ether')});
      const safe_ = await SafeTracker.new(_Oracle, 10000);
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.02", "ether")})
      assert.equal(await safe_.collateral(accounts[0]), web3.utils.toWei("0.02", "ether"));
        });

  // Test opening a CDP position by depositing Collateral and parially withdrawing collateral; + system accounting checks.
  it("Deposit 0.1 RBTC, Withdraw 0.09 RBTC, verify collateral balance is 1 RBTC [[removeCollateral]]", async function () {
      const safe_ = await SafeTracker.new(_Oracle, 10000);
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("10", "ether")});
      await safe_.removeCollateral(web3.utils.toWei("9", "ether"));
      assert.equal(await safe_.collateral(accounts[0]), web3.utils.toWei("1", "ether"));
  });

  // Test Debt issuance based on the rules of the protocol
  it("[[takeDebt]] Deposit 0.125 rbtc, mint 0.1 xBTC debt, verify debtIssued", async function () {
      const safe_ = await SafeTracker.new(_Oracle, 10000);
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.125", "ether")});
      //add safe to coin
      //const coin_ = Coin.at("0x597a0F47572a359410883A58eb001aca990226ec");
      console.log(safe_.address);
      const coin_ = await Coin.new("XBTC", "XBTC", "5777");
      await coin_.addAuthorization(safe_.address);
      await safe_.setCoin(coin_.address);
      await safe_.takeDebt(web3.utils.toWei("0.10", "ether"));
      assert.equal(await safe_.debtIssued(accounts[0]), web3.utils.toWei("0.10", "ether"));
    });

  // Test take out xBTC debt, transfer to another user, who redeems it at current redemption rate ($20000 by default)
  // Note redemption can be carried out by any user that holds the xBTC, whereas CDP functions (takedebt, returndebt, removeCollateral)
  // can only be performed by the creator of the CDP.
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

  // Test attempted removal of collateral while debt is pending - should FAIL.


});
