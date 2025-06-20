const hre = require("hardhat");
const { getSelectors } = require("./helpers");
const { saveAddressToEnv } = require("./saveAddressToEnv");

async function deployDiamond() {
  const [deployer] = await hre.ethers.getSigners();
  const networkName = hre.network.name.toUpperCase(); // e.g., LOCALHOST or SEPOLIA
  console.log(`📡 Network: ${networkName}`);
  console.log("Deploying contracts with account:", deployer.address);

  // 1. Deploy DiamondCutFacet
  const DiamondCutFacet = await hre.ethers.getContractFactory("DiamondCutFacet");
  const diamondCutFacet = await DiamondCutFacet.deploy();
  await diamondCutFacet.waitForDeployment();
  console.log(`✅ DiamondCutFacet deployed: ${diamondCutFacet.target}`);

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

  // 2. Deploy all facets and record their addresses
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

    // Save each facet address to .env
    saveAddressToEnv(`${name.toUpperCase()}_ADDRESS_${networkName}`, facet.target);
  }

  // 3. Deploy Diamond
  const Diamond = await hre.ethers.getContractFactory("FortuneNXTDiamond");
  const diamond = await Diamond.deploy(cut);
  await diamond.waitForDeployment();
  console.log(`✅ Diamond deployed: ${diamond.target}`);

  // 4. Save Diamond address to .env
  saveAddressToEnv(`DIAMOND_ADDRESS_${networkName}`, diamond.target);
}

deployDiamond()
  .then(() => process.exit(0))
  .catch(error => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
  
