// See <http://truffleframework.com/docs/advanced/configuration>
// to customize your Truffle configuration!
const fs = require('fs');
const HDWalletProvider = require('@truffle/hdwallet-provider');

const mnemonicPhrase = process.env["MNEMONIC"];


//Update gas price Testnet
/* Run this first, to use the result in truffle-config:
  curl https://public-node.testnet.rsk.co/ -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' \
    > .minimum-gas-price-testnet.json
*/
const gasPriceTestnetRaw = fs.readFileSync(".minimum-gas-price-testnet.json").toString().trim();
const minimumGasPriceTestnet = parseInt(JSON.parse(gasPriceTestnetRaw).result.minimumGasPrice, 16);
if (typeof minimumGasPriceTestnet !== 'number' || isNaN(minimumGasPriceTestnet)) {
  throw new Error('unable to retrieve network gas price from .gas-price-testnet.json');
}
console.log("Minimum gas price Testnet: " + minimumGasPriceTestnet);

//Update gas price Mainnet
/* Run this first, to use the result in truffle-config:
  curl https://public-node.rsk.co/ -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' \
    > .minimum-gas-price-mainnet.json
*/
const gasPriceMainnetRaw = fs.readFileSync(".minimum-gas-price-mainnet.json").toString().trim();
const minimumGasPriceMainnet = parseInt(JSON.parse(gasPriceMainnetRaw).result.minimumGasPrice, 16);
if (typeof minimumGasPriceMainnet !== 'number' || isNaN(minimumGasPriceMainnet)) {
  throw new Error('unable to retrieve network gas price from .gas-price-mainnet.json');
}
console.log("Minimum gas price Mainnet: " + minimumGasPriceMainnet);


module.exports = {

   // SETUP for testing using LOCAL RSKJ TESTNET NODE, setup on localhost at port 4444.
   // eth/metamask derivationPath used.
  networks: {
    dev: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: "5777",       // Any network (default: none)
    },
    mainnet: {
      provider: () => new HDWalletProvider(mnemonic, 'https://public-node.rsk.co', 0, 1, true, "m/44'/137'/0'/0/"),
      network_id: 30,
      gasPrice: Math.floor(minimumGasPriceMainnet * 1.02),
      networkCheckTimeout: 1e9
    },
    testnet: {
      provider: () => new HDWalletProvider({
        mnemonic: {
            phrase: mnemonicPhrase,
          },
          providerOrUrl: 'http://localhost:4444/',
          pollingInterval: 10e3,
          derivationPath: "m/44'/37310'/0'/0/N",
          index: 0,
        }),
      network_id: 31,
      gasPrice: Math.floor(minimumGasPriceTestnet * 1.1),
      networkCheckTimeout: 1e9,
      deploymentPollingInterval: 15e3,
      from: "0xB0084105778f6B22a55C4828B115b4d26C08f3f2",
    },
    testnet2: {
      provider: () => new HDWalletProvider(mnemonicPhrase, 'http://localhost:4444/',0),
      network_id: 31,
      gasPrice: Math.floor(minimumGasPriceTestnet * 1.1),
      networkCheckTimeout: 1e9,
      deploymentPollingInterval: 15e3,
      from: "0xB0084105778f6B22a55C4828B115b4d26C08f3f2",
  },
},
  // Set default mocha options here, use special reporters etc.
  mocha: {  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.6.7",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      //  optimizer: {
      //    enabled: false,
      //    runs: 200
      //  },
      //  evmVersion: "byzantium"
      // }
    }
  }
}
