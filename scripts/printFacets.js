// scripts/printFacets.js

const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const diamondAddressPath = path.join(__dirname, "../abi/FortuneNXTDiamond.json");

  if (!fs.existsSync(diamondAddressPath)) {
    throw new Error("⛔ Could not find Diamond deployment. Make sure to run the deploy script first.");
  }

  const diamondJson = require(diamondAddressPath);
  const diamondAddress = diamondJson.address;

  const diamondLoupeFacet = await hre.ethers.getContractAt("DiamondLoupeFacet", diamondAddress);
  const facets = await diamondLoupeFacet.facets();

  console.log(`🧩 Diamond Address: ${diamondAddress}`);
  console.log(`\n📦 Facets (${facets.length}) deployed:\n`);

  facets.forEach((facet, idx) => {
    console.log(`✅ ${idx + 1}. ${facet.facetAddress}`);
    facet.functionSelectors.forEach((sel) => {
      console.log(`   ↳ ${sel}`);
    });
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
// To run this script, use the command:
// npx hardhat run scripts/printFacets.js --network localhost