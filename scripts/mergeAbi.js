const fs = require("fs");
const path = require("path");

const artifactsDir = path.resolve(__dirname, "../artifacts/contracts");
const outputPath = path.resolve(__dirname, "../UnifiedDiamondABI.json");

const mergedABI = [];

function collectABIs(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      collectABIs(fullPath); // Recurse
    } else if (entry.isFile() && entry.name.endsWith(".json")) {
      try {
        const jsonContent = JSON.parse(fs.readFileSync(fullPath, "utf8"));
        if (Array.isArray(jsonContent.abi)) {
          mergedABI.push(...jsonContent.abi);
          console.log(`✅ Merged ABI from: ${entry.name}`);
        }
      } catch (err) {
        console.error(`❌ Error reading: ${entry.name}`, err.message);
      }
    }
  }
}

collectABIs(artifactsDir);

// Optional: deduplicate entries
const seen = new Set();
const unifiedABI = mergedABI.filter((item) => {
  const key = `${item.type}:${item.name || ""}`;
  if (seen.has(key)) return false;
  seen.add(key);
  return true;
});

// Save merged ABI
fs.writeFileSync(outputPath, JSON.stringify(unifiedABI, null, 2));
console.log(`\n✅ Unified ABI written to: ${outputPath}`);
// Optionally, you can also log the number of unique selectors
console.log(`Total unique selectors: ${unifiedABI.length}`);    