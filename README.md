# xBTC Stablecoin System - Core

This repo contains the core contracts of the xBTC stablecoin system (XSS).

# About
XSS is a a capital-efficient stablecoin system with an explicit and autonomous redemption price adjustment mechanism, offering a practical way for ensuring mid-and-long term stability & value appreciation of the currency. It is aimed at solving the twin problems of inflation of current stable assets (USDC, DAI, RAI), as well as high volatility in appreciating assets (BTC). We approach this problem by designing an explicit peg to an algorithmic measure of stable/appreciating purchasing power, instead of pegging directly to USD (loses purchasing power), or a scarce asset like BTC (too volatile).

xBTC protocol is governed by the EVI DAO, which sets the XDR savings rate as a further mechanism to stabilise price and earn protocol revenue.
For more information on the protocol, check out the Technical Documentation and the Whitepaper.

# Usage

Ensure you have the latest version of NodeJS, npm and truffle.js installed, then follow the following steps
to deploy contracts on RSK Testnet and run tests:


1. Setup
`git clone`
`cd xss`
`npm install`

2. Export mnemonic
`export MNEMONIC= "star earth moon ... "` [Replace with actual mnemonic of account with testnet RBTC]

3. Compile contracts
`truffle compile`

4. Run tests
`truffle test --network=testnet`
