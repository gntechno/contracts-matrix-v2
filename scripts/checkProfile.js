require("dotenv").config();
const hre = require("hardhat");

async function main() {
  const diamond = await hre.ethers.getContractAt(
    "UserViewFacet",
    process.env.DIAMOND_ADDRESS
  );

  const user = "0xd548ba62e0f01c99771c707cc740431665617f3e";
  const profile = await diamond.getUserProfile(user);
  const matrix = await diamond.getMatrixNode(user, 3);

  console.log("== User Profile ==");
  console.log(profile);

  console.log("== Matrix Info ==");
  console.log(matrix);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
