const SafeTracker = artifacts.require("SafeTracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");

web3=require('web3')

//RSK Testnet Deployed Addresses:
_Oracle ="0x7B9DE95870c64c7b521Fa628f6b45aa2e6497e8c";
_Coin ="0x67ead23FCa16bDC4321d00b4504BfbA3AcE22A93";

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
  it("Deposit 0.125 rbtc, mint 0.1 xBTC debt, verify debtIssued [[takeDebt]]", async function () {
      const safe_ = await SafeTracker.new(_Oracle, 10000);
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.125", "ether")});
      //add safe to coin
      //const coin_ = Coin.at("0x597a0F47572a359410883A58eb001aca990226ec");
      console.log(safe_.address);
      const coin_ = await Coin.new("XBTC", "XBTC", "5777");
      await coin_.addAuthorization(safe_.address);
      await safe_.setCoin(coin_.address);
      await safe_.takeDebt(web3.utils.toWei("0.10", "ether"));
      // assert.equal(await safe_.debtIssued(accounts[0]), web3.utils.toWei("0.10", "ether"));
    });

  // Test take out xBTC debt, transfer to another user, who redeems it at current redemption rate ($20000 by default)
  // Note redemption can be carried out by any user that holds the xBTC, whereas CDP functions (takedebt, returndebt, removeCollateral)
  // can only be performed by the creator of the CDP.
  it("Deposit 0.125 rbtc, mint 0.1 xBTC debt, transfer to accounts[1], redeem for eth [[redeemCoins]]", async function () {
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
      await safe_.redeemCoins(web3.utils.toWei("9", "ether"), {from:accounts[1]});
      //assert.equal(coin_.balanceOf(accounts[1]), web3.utils.toWei("1", "ether"));
  });

  // Test attempted removal of collateral while debt is pending - should FAIL.


});
