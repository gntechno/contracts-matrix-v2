require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-abi-exporter");
require("hardhat-contract-sizer");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28", // or the version that satisfies all your contracts
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
    },
    localhost: {
      url: "http://127.0.0.1:8545", // Ganache default port
      chainId: 31337, // Ganache default chain ID
      accounts: {
        mnemonic: "test test test test test test test test test test test junk",
        count: 120, // ✅ Increase to at least 103 users
      },
    }
  }
};