require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");

const path = require("path");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config = {
  defaultNetwork: "hardhat",

  networks: {
    hardhat: {
      chainId: 31337,
      allowUnlimitedContractSize: true, // useful for diamond deployments
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
    coreTestnet: {
      url: process.env.CORE_RPC_URL || "", // e.g., https://rpc.test.btcs.network
      chainId: 1115, // Core Testnet chain ID
      accounts: [process.env.PRIVATE_KEY].filter(Boolean),
    },
    coreMainnet: {
      url: process.env.CORE_MAINNET_RPC_URL || "",
      chainId: 1116, // Core Mainnet chain ID
      accounts: [process.env.PRIVATE_KEY].filter(Boolean),
    },
  },

  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  namedAccounts: {
    deployer: {
      default: 0,
    },
  },

  etherscan: {
    apiKey: {
      coreMainnet: process.env.ETHERSCAN_API_KEY || "", // If CoreScan supported via Etherscan-compatible endpoint
    },
  },

  mocha: {
    timeout: 200000, // useful for integration tests
  },
};

module.exports = config;
