// scripts/upgrade/add-loupe-facet.js
const { ethers } = require("hardhat");

async function main() {
  const diamondAddress = "0x610178dA211FEF7D417bC0e6FeD39F05609AD788"; // ✅ Your deployed diamond address
  const loupeFacetName = "DiamondLoupeFacet";

  // Deploy DiamondLoupeFacet if not already
  const LoupeFacet = await ethers.getContractFactory(loupeFacetName);
  const loupeFacet = await LoupeFacet.deploy();
  await loupeFacet.waitForDeployment();

  console.log(`✅ ${loupeFacetName} deployed:`, await loupeFacet.getAddress());

  const loupeSelectors = getSelectors(loupeFacet);

  // Use diamondCut to add loupe functions
  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);
  const tx = await diamondCut.diamondCut(
    [
      {
        facetAddress: await loupeFacet.getAddress(),
        action: 0, // Add
        functionSelectors: loupeSelectors,
      },
    ],
    ethers.ZeroAddress,
    "0x"
  );

  console.log("⏳ Adding DiamondLoupeFacet...");
  const receipt = await tx.wait();
  if (!receipt.status) {
    throw Error("❌ Diamond upgrade failed.");
  }
  console.log("✅ DiamondLoupeFacet added successfully.");
}

// Utility to extract selectors
function getSelectors(contract) {
  const iface = contract.interface;
  return Object.keys(iface.functions).map(fn => iface.getFunction(fn).selector);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
