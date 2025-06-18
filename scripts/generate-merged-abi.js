const fs = require("fs");
const path = require("path");

const facets = [
  "DiamondCutFacet",
  "AdminFacet",
  "IncomeFacet",
  "LevelIncomeFacet",
  "MagicPoolFacet",
  "MatrixFacet",
  "PriceFeedFacet",
  "PurchaseFacet",
  "RegistrationFacet",
  "UserViewFacet",
];

const basePath = path.join(__dirname, "..", "artifacts", "contracts");
const outputAbiPath = path.join(__dirname, "..", "abi", "FortuneNXTDiamond.json");

let mergedAbi = [];

for (const name of facets) {
  // Check both root and facet/ subfolder
  const artifactPath = path.join(basePath, `facets/${name}.sol/${name}.json`);
  if (!fs.existsSync(artifactPath)) {
    console.warn(`⚠️ Missing artifact for ${name}`);
    continue;
  }

  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
  const abi = artifact.abi.filter((item) => item.type === "function" || item.type === "event");
  mergedAbi = mergedAbi.concat(abi);
}

if (!fs.existsSync(path.dirname(outputAbiPath))) {
  fs.mkdirSync(path.dirname(outputAbiPath), { recursive: true });
}

fs.writeFileSync(outputAbiPath, JSON.stringify(mergedAbi, null, 2));
console.log(`✅ Merged ABI saved to ${outputAbiPath}`);
