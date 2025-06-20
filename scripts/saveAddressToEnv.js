const fs = require("fs");
const path = require("path");

/**
 * Saves contract address to .env file with network support.
 * Key format: <CONTRACT_NAME>_ADDRESS_<NETWORK>
 */
function saveAddressToEnv(key, address) {
  const envPath = path.resolve(__dirname, "../.env");

  let env = "";
  if (fs.existsSync(envPath)) {
    env = fs.readFileSync(envPath, "utf-8");
  }

  const pattern = new RegExp(`^${key}=.*$`, "m");
  const newLine = `${key}=${address}`;

  if (pattern.test(env)) {
    env = env.replace(pattern, newLine);
  } else {
    env += `\n${newLine}`;
  }

  fs.writeFileSync(envPath, env.trim() + "\n", "utf-8");
  console.log(`📦 Saved ${key} to .env`);
}

module.exports = { saveAddressToEnv };
// Usage example:
// const { saveAddressToEnv } = require("./saveAddressToEnv");