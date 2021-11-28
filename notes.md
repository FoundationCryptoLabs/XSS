0x75230546447272Cd7b29f34F989e4Ccd2F97f150

it("Deposit 2 ether, check collateral balance [[depositCollateral]]", async function () {
  const safe_ = await SafeTracker.new(_Oracle, 10000);
  await safe_.depositCollateral({from:accounts[0], value: web3.utils.toWei("0.2", "ether")})
  assert.equal(await safe_.collateral(accounts[0]), web3.utils.toWei("0.2", "ether"));
    });


    it("Deposit 12.5 btc, mint 10 xBTC debt, check debtIssued [[takeDebt]]", async function () {
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
