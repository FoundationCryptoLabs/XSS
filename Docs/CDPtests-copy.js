const CDPtracker = artifacts.require("CDPtracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");

web3=require('web3')

//RSK Testnet Deployed Addresses:
_Oracle ="0xDEf2acE4F0991a22d0CC6947C2186b25e43b23A5";
_Coin ="0xd55C40a83fa1C23F40AC86b4a4974577c10cD8C0";

//_Oracle="0x29e30dC86578E336a0930012315aed2d398802b4"
// Local Ganache deployed addresses:
_Oracle ="0xD2D9Ae45A4df94CA4c921F65cb8Ece0f968140f5";
_Coin ="0xc3dDD87D860C7b2b5e11F57026B603D1684DAeEB";


contract("Coin", (accounts) => {
});

contract("CDPtracker", (accounts) => {
  // Test opening a CDP position by depositing Collateral


  // Test take out xBTC debt, transfer to another user, who redeems it at current redemption rate ($20000 by default)
  // Note redemption can be carried out by any user that holds the xBTC, whereas CDP functions (takedebt, returndebt, removeCollateral)
  // can only be performed by the creator of the CDP.
  it("Deposit 0.0125 rbtc, mint 0.01 xBTC debt, transfer to accounts[1], redeem for eth [[redeemCoins]]", async function () {
      const safe_ = await CDPtracker.at("0xc4aed98e77fcd523ee6506d18efb39963029c873");
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.0125", "ether")});
      //add safe to coin
      //const coin_ = Coin.at("0x597a0F47572a359410883A58eb001aca990226ec");
      console.log(safe_.address);
      const coin_ = await Coin.at("0x3bf9e5bb65c580fbe1936bd7edd60aaad4f38eb0");
      await coin_.addAuthorization(safe_.address);
      await safe_.setCoin(coin_.address);
      await safe_.takeDebt(web3.utils.toWei("0.010", "ether"));
      // assert.equal(await safe_.debtIssued(accounts[0]), web3.utils.toWei("0.010", "ether"));
      await coin_.transfer(accounts[1], web3.utils.toWei("0.009", "ether"));
      // assert.equal(coin_.balanceOf(accounts[1], web3.utils.toWei("0.09", "ether")));
      // await safe_.redeemCoins(web3.utils.toWei("0.009", "ether"), {from:accounts[1]});
      //assert.equal(coin_.balanceOf(accounts[1]), web3.utils.toWei("1", "ether"));
  });

  // Test attempted removal of collateral while debt is pending - should FAIL.

});
