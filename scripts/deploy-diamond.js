const hre = require("hardhat");
const { getSelectors } = require("./helpers");

async function deployDiamond() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // 1. Deploy DiamondCutFacet
  const DiamondCutFacet = await hre.ethers.getContractFactory("DiamondCutFacet");
  const diamondCutFacet = await DiamondCutFacet.deploy();
  await diamondCutFacet.waitForDeployment();
  console.log(`✅ DiamondCutFacet deployed: ${diamondCutFacet.target}`);

  // 2. Define all facet names
  const facetNames = [
    "AdminFacet",
    "IncomeFacet",
    "LevelIncomeFacet",
    "MagicPoolFacet",
    "MatrixFacet",
    "PriceFeedFacet",
    "PurchaseFacet",
    "RegistrationFacet",
    "UserViewFacet",
    "DiamondLoupeFacet"

  ];

  const cut = [];
  const selectorMap = new Map(); // Tracks already added selectors

  // 3. Deploy facets and build diamond cut
  for (const name of facetNames) {
    const Facet = await hre.ethers.getContractFactory(name);
    const facet = await Facet.deploy();
    await facet.waitForDeployment();
    console.log(`✅ ${name} deployed: ${facet.target}`);

    const attached = await Facet.attach(facet.target);
    const selectors = getSelectors(attached);

    const uniqueSelectors = selectors.filter(selector => {
      if (selectorMap.has(selector)) {
        console.warn(`⚠️  Skipping duplicate selector ${selector} from ${name}, already in ${selectorMap.get(selector)}`);
        return false;
      }
      selectorMap.set(selector, name);
      return true;
    });

    if (uniqueSelectors.length === 0) {
      console.warn(`⚠️  Skipping ${name} — no unique selectors.`);
      continue;
    }

    cut.push({
      facetAddress: facet.target,
      action: 0, // Add
      functionSelectors: uniqueSelectors,
    });
  }

  // 4. Deploy Diamond with initial cut
  const Diamond = await hre.ethers.getContractFactory("FortuneNXTDiamond");
  const diamond = await Diamond.deploy(cut);
  await diamond.waitForDeployment();
  console.log(`✅ Diamond deployed: ${diamond.target}`);
}

deployDiamond()
  .then(() => process.exit(0))
  .catch(error => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
// This script deploys a diamond proxy contract with multiple facets.
// It ensures that each facet's function selectors are unique and logs the deployment process.
