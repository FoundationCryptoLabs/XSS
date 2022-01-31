const CDPtracker = artifacts.require("CDPtracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");

web3=require('web3')

//RSK Testnet Deployed Addresses:
_Oracle ="0x6fAF06e91a6aDB799d6211551fA09BB276a4c5E3";
_Coin ="0x53c7eC0675885769a01E0FA351af0b3E61E8FE07";

//_Oracle="0x29e30dC86578E336a0930012315aed2d398802b4"

contract("CDPtracker", (accounts) => {
  it("Take 0.01 xBTC debt, check interest rate is being accrued", async function() {
    const safe_ = await CDPtracker.new(_Oracle, 10000);
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
    const cz = await safe_.updateDebt2.call(accounts[0]);
    const cz_number = cz.toString(); //BigInt(cz);
    //assert.equal(await safe_.debtIssued(accounts[0]), web3.utils.toWei("0.10", "ether"));
    assert.equal(cz_number, (web3.utils.toWei("0.105", "ether")).toString()); // 5% interest should have accrued.
  });

});
