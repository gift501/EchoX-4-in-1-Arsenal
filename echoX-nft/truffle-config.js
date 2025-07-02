require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
const path = require("path");

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
      network_id: 421614,
      confirmations: 2,
      timeoutBlocks: 500,
      skipDryRun: true
    }
  },

  contracts_directory: "./contracts",
  contracts_build_directory: "./build/contracts",

  compilers: {
    solc: {
      version: "0.8.20",
      settings: {
        optimizer: {
          enabled: true,
          runs: 100000
        },
        // Change this line to true
        viaIR: true // This line has been corrected
      }
    }
  }
};