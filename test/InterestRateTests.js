const SafeTracker = artifacts.require("CDPtracker");
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
