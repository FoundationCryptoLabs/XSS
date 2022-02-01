const SafeTracker = artifacts.require("CDPtracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");

web3=require('web3')

//RSK Testnet Deployed Addresses:

//locally deployed addresses (please change these after running truffle migrate --network=dev)
_Oracle ="0xD2D9Ae45A4df94CA4c921F65cb8Ece0f968140f5";
_Coin ="0xc3dDD87D860C7b2b5e11F57026B603D1684DAeEB";

//_Oracle="0x29e30dC86578E336a0930012315aed2d398802b4"

contract("SafeTracker", (accounts) => {
  it("Take 0.01 xBTC debt, check interest rate is being accrued", async function() {
    const safe_ = await SafeTracker.new(_Oracle, 10000);
    await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("2", "ether")});
    // add safe to coin
    // const coin_ = Coin.at("0x597a0F47572a359410883A58eb001aca990226ec");
    console.log(safe_.address);
    const coin_ = await Coin.new("XBTC", "XBTC", "5777");
    await coin_.addAuthorization(safe_.address);
    await safe_.setCoin(coin_.address);
    await safe_.takeDebt(web3.utils.toWei("0.1", "ether"));
    function timeout(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    await timeout(5000);
    const cz = await safe_.updateUserDebt2.call(accounts[0]);
    const cz_number = cz.toString(); //BigInt(cz);
    //assert.equal(await safe_.debtIssued(accounts[0]), web3.utils.toWei("0.10", "ether"));
    assert.equal(cz_number, (web3.utils.toWei("0.105", "ether")).toString()); // 5% interest should have accrued.
  });

});