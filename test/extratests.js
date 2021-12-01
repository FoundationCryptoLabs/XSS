const CDPtracker = artifacts.require("CDPtracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");

web3=require('web3')

//RSK Testnet Deployed Addresses:
_Oracle ="0x2Ef2757bD2c469a7F8afa251f17700aaa6B9F3B7";
_Coin ="0x0eD122216A1889f767060F9311aEbB083860F58a";

//_Oracle="0x29e30dC86578E336a0930012315aed2d398802b4"


// Extra tests moved here to avoid Rate Limit Errors while testing on RSK testnet.
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

contract("CDPtracker", (accounts) => {
it("Deposit 0.002 RBTC, check collateral balance [[depositCollateral]]", async function () {
    const safe_ = await CDPtracker.new(_Oracle, 10000);
    await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.002", "ether")})
    assert.equal(await safe_.collateral(accounts[0]), web3.utils.toWei("0.002", "ether"));
      });

// Test opening a CDP position by depositing Collateral and parially withdrawing collateral; + system accounting checks.
it("Deposit 0.01 RBTC, Withdraw 0.009 RBTC, verify collateral balance is 1 RBTC [[removeCollateral]]", async function () {
    const safe_ = await CDPtracker.new(_Oracle, 10000);
    await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.010", "ether")});
    await safe_.removeCollateral(web3.utils.toWei("0.009", "ether"));
    assert.equal(await safe_.collateral(accounts[0]), web3.utils.toWei("0.001", "ether"));
});

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
