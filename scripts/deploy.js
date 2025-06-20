
// scripts/deploy.js
// Deploys the FortuneNXTDiamond contract and saves its address to .env

const hre = require("hardhat");
const { saveAddressToEnv } = require("../scripts/saveAddressToEnv");

async function main() {
  const Diamond = await hre.ethers.getContractFactory("FortuneNXTDiamond");
  const diamond = await Diamond.deploy();

  await diamond.waitForDeployment();
  const address = await diamond.getAddress();

  console.log("✅ Diamond deployed at:", address);

  // Save to .env
  saveAddressToEnv("DIAMOND", address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
