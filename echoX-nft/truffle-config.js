require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    arbSepolia: {
      provider: () =>
        new HDWalletProvider({
          privateKeys: [process.env.PRIVATE_KEY],
          providerOrUrl: process.env.ARBITRUM_SEPOLIA_RPC,
          numberOfAddresses: 1,
          shareNonce: true,
          pollingInterval: 8000
        }),
      network_id: 421614, // Correctly placed here
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: "0.8.20"
    }
  }
};
