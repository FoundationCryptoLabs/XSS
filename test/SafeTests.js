const SafeTracker = artifacts.require("SafeTracker");
const Coin = artifacts.require("Coin");
const Oracle = artifacts.require("Orc");



contract("2nd MetaCoin test", async accounts => {
  it("deposit 1 ether collateral from first account", async () => {
    const _coin = Coin.at('0x597a0F47572a359410883A58eb001aca990226ec');
    const _orc = Oracle.at('0x5921c0C11C3f38EdE7c0B2a35119f8f6ebac4079');
    const _safes = SafeTracker.at('0x3aDBC248888A046C31C870684A543c74809a74b7');
    const balance = await _safes.depositCollateral(0, {from:accounts[0], value:2000000000000});
    // assert.equal(balance.valueOf(), 10000);
  });

  it("should call a function that depends on a linked library", async () => {
    const meta = await MetaCoin.deployed();
    const outCoinBalance = await meta.getBalance.call(accounts[0]);
    const metaCoinBalance = outCoinBalance.toNumber();
    const outCoinBalanceEth = await meta.getBalanceInEth.call(accounts[0]);
    const metaCoinEthBalance = outCoinBalanceEth.toNumber();
    assert.equal(metaCoinEthBalance, 2 * metaCoinBalance);
  });

  it("should send coin correctly", async () => {
    // Get initial balances of first and second account.
    const account_one = accounts[0];
    const account_two = accounts[1];
    let balance;

    const amount = 10;

    const instance = await MetaCoin.deployed();
    const meta = instance;

    balance = await meta.getBalance.call(account_one);
    const account_one_starting_balance = balance.toNumber();

    balance = await meta.getBalance.call(account_two);
    const account_two_starting_balance = balance.toNumber();
    await meta.sendCoin(account_two, amount, { from: account_one });

    balance = await meta.getBalance.call(account_one);
    const account_one_ending_balance = balance.toNumber();

    balance = await meta.getBalance.call(account_two);
    const account_two_ending_balance = balance.toNumber();

    assert.equal(
      account_one_ending_balance,
      account_one_starting_balance - amount,
      "Amount wasn't correctly taken from the sender"
    );
    assert.equal(
      account_two_ending_balance,
      account_two_starting_balance + amount,
      "Amount wasn't correctly sent to the receiver"
    );
  });
});
