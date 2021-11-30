const CDPtracker = artifacts.require("CDPtracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");

web3=require('web3')

//RSK Testnet Deployed Addresses:
//_Oracle ="0x2Ef2757bD2c469a7F8afa251f17700aaa6B9F3B7";
_Coin ="0x0eD122216A1889f767060F9311aEbB083860F58a";

_Oracle="0x29e30dC86578E336a0930012315aed2d398802b4"


contract("Coin", (accounts) => {
});

contract("CDPtracker", (accounts) => {
  // Test opening a CDP position by depositing Collateral
  // Test take out xBTC debt, transfer to another user, who redeems it at current redemption rate ($20000 by default)
  // Note redemption can be carried out by any user that holds the xBTC, whereas CDP functions (takedebt, returndebt, removeCollateral)
  // can only be performed by the creator of the CDP.
  it("Deposit 0.0125 rbtc, mint 0.01 xBTC debt, transfer to accounts[1], redeem for eth [[redeemCoins]]", async function () {
      const safe_ = await CDPtracker.new(_Oracle, 10000);
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.0125", "ether")});
      //add safe to coin
      //const coin_ = Coin.at("0x597a0F47572a359410883A58eb001aca990226ec");
      console.log(safe_.address);
      const coin_ = await Coin.new("XBTC", "XBTC", "5777");
      await coin_.addAuthorization(safe_.address);
      await safe_.setCoin(coin_.address);
      await safe_.takeDebt(web3.utils.toWei("0.010", "ether"));
      // assert.equal(await safe_.debtIssued(accounts[0]), web3.utils.toWei("0.010", "ether"));
      await coin_.transfer(accounts[1], web3.utils.toWei("0.009", "ether"));
      // assert.equal(coin_.balanceOf(accounts[1], web3.utils.toWei("0.09", "ether")));
      await safe_.redeemCoins(web3.utils.toWei("0.009", "ether"), {from:accounts[1]});
      //assert.equal(coin_.balanceOf(accounts[1]), web3.utils.toWei("1", "ether"));
  });

  // Test attempted removal of collateral while debt is pending - should FAIL.
  it("Deposit 0.0125 rbtc, mint 0.01 xBTC debt, attempt to withdraw 0.0125 btc, FAILS [[expected error: CDPTracker/debt-not-repaid]]", async function () {
        const safe_ = await CDPtracker.new(_Oracle, 10000);
        await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.0125", "ether")});
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
