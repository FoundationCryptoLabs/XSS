const SafeTracker = artifacts.require("CDPTracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");

web3=require('web3')



//locally deployed addresses (please change these after running truffle migrate --network=dev)
_Oracle ="0x6f866e57B012e9E682906842c2129fddD664eDA1";
_Coin ="0x53A050dEa87F8A56c70705ba2dcA19d04e7177ac";

//RSK Testnet Deployed Addresses [Uncomment for testnet]
//_Oracle ="0x2Ef2757bD2c469a7F8afa251f17700aaa6B9F3B7";
//_Coin ="0x3bf9e5bb65c580fbe1936bd7edd60aaad4f38eb0";


contract("SafeTracker", (accounts) => {
  // web3.eth.getBalance(accounts[0], (err, res) => console.log (res))

  // Test opening a CDP position by depositing Collateral
  it("Deposit 0.02 RBTC, check collateral balance [[depositCollateral]]", async function () {
      //await web3.eth.sendTransaction({to:accounts[0], from:accounts[1], value:web3.utils.toWei('30', 'ether')});
      const safe_ = await SafeTracker.new(_Oracle, 10000);
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.02", "ether")});
      const result_ = await safe_.gsafes.call(accounts[0], "collateral");
      assert.equal(result_, web3.utils.toWei("0.02", "ether"));
        });

  // Test opening a CDP position by depositing Collateral and parially withdrawing collateral; + system accounting checks.
  it("Deposit 0.010 RBTC, Withdraw 0.09 RBTC, verify collateral balance is 0.001 RBTC [[removeCollateral]]", async function () {
      const safe_ = await SafeTracker.new(_Oracle, 10000);
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.010", "ether")});
      await safe_.removeCollateral(web3.utils.toWei("0.009", "ether"));
      const result_ = await safe_.gsafes.call(accounts[0], "collateral");
      assert.equal(result_, web3.utils.toWei("0.001", "ether"));
  });

  // Test Debt issuance based on the rules of the protocol
  it("[[takeDebt]] Deposit 0.0125 rbtc, mint 0.01 xBTC debt, verify debtIssued.", async function () {
      const safe_ = await SafeTracker.new(_Oracle, 10000);
      await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.0125", "ether")});
      //add safe to coin
      //const coin_ = Coin.at("0x597a0F47572a359410883A58eb001aca990226ec");
      console.log(safe_.address);
      const coin_ = await Coin.new("XBTC", "XBTC", "5777");
      await coin_.addAuthorization(safe_.address);
      await safe_.setCoin(coin_.address);
      await safe_.takeDebt(web3.utils.toWei("0.010", "ether"));
      const result_ = await safe_.gsafes.call(accounts[0], "debtissued");
      assert.equal(result_, web3.utils.toWei("0.010", "ether"));
    });

  // Test take out xBTC debt, transfer to another user, who redeems it at current redemption rate ($20000 by default)
  // Note redemption can be carried out by any user that holds the xBTC, whereas CDP functions (takedebt, returndebt, removeCollateral)
  // can only be performed by the creator of the CDP.

  // Test attempted removal of collateral while debt is pending - should FAIL.


});
