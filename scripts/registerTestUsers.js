const { ethers } = require("ethers");
const mongoose = require("mongoose");
const User = require("../src/models/User");
const Slot = require("../src/models/Slot");
require("dotenv").config();

const diamondAbi = require("../src/abi/diamondAbi.json");
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contract = new ethers.Contract(process.env.CONTRACT_ADDRESS, diamondAbi, signer);

async function registerUsers() {
  await mongoose.connect(process.env.MONGODB_URI, {});

  const users = [];
  const accounts = await provider.listAccounts();

  for (let i = 0; i < 102; i++) {
    const username = `P${i}`;
    const wallet = accounts[i];
    const slotLevel = Math.floor(Math.random() * 7) + 1;

    const referrer = i === 0 ? ethers.ZeroAddress : accounts[i - 1];

    try {
      const tx = await contract.register(referrer, { from: wallet, gasLimit: 5000000 });
      await tx.wait();

      console.log(`✅ Registered ${username} referred by ${referrer}`);

      await User.create({
        username,
        walletAddress: wallet,
        referredBy: i === 0 ? null : accounts[i - 1],
        totalEarnings: 0,
        activeSlots: Array.from({ length: slotLevel }, (_, j) => j + 1),
      });

      for (let s = 1; s <= slotLevel; s++) {
        await Slot.create({
          slotId: s,
          address: wallet,
          active: true,
        });
      }

    } catch (err) {
      console.error(`❌ Failed to register ${username}`, err.message);
    }
  }

  console.log("🎯 Registration script completed.");
  process.exit(0);
}

registerUsers();
