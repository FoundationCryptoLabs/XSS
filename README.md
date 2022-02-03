# xBTC Stablecoin System - Core

This repo contains the core contracts of the xBTC stablecoin system (XSS).

# About
XSS is a a capital-efficient stablecoin system with an explicit and autonomous redemption price adjustment mechanism, offering a practical way for ensuring mid-and-long term stability & value appreciation of the currency. It is aimed at solving the twin problems of inflation of current stable assets (USDC, DAI, RAI), as well as high volatility in appreciating assets (BTC). We approach this problem by designing an explicit peg to an algorithmic measure of stable/appreciating purchasing power, instead of pegging directly to USD (loses purchasing power), or a scarce asset like BTC (too volatile).

xBTC protocol is governed by the EVI DAO, which sets the XSR savings rate as a further mechanism to stabilise price and earn protocol revenue.
For more information on the protocol, check out the Technical Documentation and the Whitepaper.

# Usage

Ensure you have the latest version of NodeJS, npm and truffle.js installed.

1. Setup
`git clone`
`cd xss`
`npm install`

2. Export mnemonic
`export MNEMONIC= "star earth moon ... "` (Replace with actual mnemonic of account with testnet RBTC in accounts[0] AND accounts[1])

*A. Testing locally using ganache*
Ensure ganache local node is running on port 7545.
Use the Ganache created mnemonic for step (2) above.

3. Compile and migrate contracts
`truffle migrate --network=dev`

4. add contract addresses to all 3 testing files [replace with addresses from step 3]:
`_Oracle ="0xD2D9Ae45A4df94CA4c921F65cb8Ece0f968140f5";
_Coin ="0xc3dDD87D860C7b2b5e11F57026B603D1684DAeEB";`

5. Run tests
`truffle test --network=dev`


*B. Testing on RSK TESTNET*
Make sure you use mnemonic for address with sufficient testRBTC for step (2) above.
6. Compile and migrate contracts
`truffle migrate --network=testnet`

7. Uncomment RSK testnet contract addresses to all 3 testing files:
`_Oracle ="0xD2D9Ae45A4df94CA4c921F65cb8Ece0f968140f5";
_Coin ="0xc3dDD87D860C7b2b5e11F57026B603D1684DAeEB";`

8. Run tests
`truffle test --network=testnet`

Contracts are deployed on the testnet on following addresses. You can also interact directly with the contract functions to test them (using rskexplorer UI or any other software). Basic tests of ERC20 functionality/authorizedAccounts functionality are excluded for simplicity in this repo.

CDPTracker[updated]: https://explorer.testnet.rsk.co/address/0x7a0984E49418759Ef975F7d1d93f5606A8055b38
Coin: https://explorer.testnet.rsk.co/address/0x3bf9e5bb65c580fbe1936bd7edd60aaad4f38eb0
Oracle: https://explorer.testnet.rsk.co/address/0x2Ef2757bD2c469a7F8afa251f17700aaa6B9F3B7
TaxCollector:https://explorer.testnet.rsk.co/address/0xd275F1D2fceB349dF85c7DF7ED7572EE8ccdf20f
