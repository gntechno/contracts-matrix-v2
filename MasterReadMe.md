# FortunityNXT – 2x2 Forced Matrix Semi-DApp

FortunityNXT is a modular, upgradeable blockchain-based income opportunity platform that leverages a 2x2 Forced Matrix MLM architecture. This system is built using the Diamond Standard (EIP-2535) to allow seamless upgrades and facet-based modularity. It operates as a **Semi-DApp**, balancing on-chain trust with off-chain scalability.

## 🔱 Architecture Overview

The system is composed of three core components:

1. **Smart Contracts** (Refactored & Modular using EIP-2535)
2. **Backend (Node.js + MongoDB)** – for syncing events, storing user data, distributing income off-chain.
3. **Frontend (React + Tailwind)** – for member dashboard and interaction with contracts via wallets.

---

## 📂 Repositories Structure

| Repository | Description |
|-----------|-------------|
| [`contracts-matrix-v2`](https://github.com/gntechnocloud/contracts) | Refactored Diamond Standard smart contracts (facets + storage) |
| [`backend`](https://github.com/gntechnocloud/backend) | Off-chain backend for income distribution, user tracking, contract event syncing |
| [`fortunity-nxt-frontend`](https://github.com/gntechnocloud/fortunity-nxt-frontend) | React-based frontend for user dashboard and wallet interaction |

---

## 🔐 Contracts Overview

- **Diamond (FortuneNXTDiamond.sol)** – Main proxy supporting DiamondCut, DiamondLoupe, and initialization.
- **Facets**:
  - `RegistrationFacet`: Handles user onboarding and referral logic.
  - `MatrixFacet`: Manages 2x2 matrix tree placement and rebirth.
  - `PurchaseFacet`: Manages slot purchases using dynamic USD/CORE price via Chainlink.
  - `LevelIncomeFacet`: Manages 25% indirect referral income across 50 levels.
  - `IncomeFacet`: Central logic for income distribution (matrix + level + admin fees).
  - `MagicPoolFacet`: Manages pool income distribution based on milestone days.
  - `UserViewFacet`: Query logic for frontend (dashboard stats).
  - `AdminFacet`: Admin controls, slot settings, emergency config.
  - `PriceFeedFacet`: CORE/USD feed with fallback manual pricing.

- **Libraries**:
  - `LibAppStorage.sol`: Diamond-compatible shared state manager.
  - `MatrixLib.sol`: Reusable matrix traversal logic.
  - `IncomeLib.sol`: Core income calculation utilities.

---

## 🧠 Backend Overview

- Built using **Express.js + MongoDB**
- Syncs all smart contract events (UserRegistered, SlotPurchased, IncomeDistributed)
- Stores off-chain user structure, rebirth cycles, payouts, and total earnings.
- Admin APIs for calculating and triggering level/magic pool distributions.
- Listener service to keep DB in sync with on-chain state.

---

## 💻 Frontend Overview

- Built with **React + Tailwind + Ethers.js**
- Wallet support: **MetaMask, TokenPocket** (Core-compatible)
- Pages:
  - Dashboard (Live stats, income breakdown)
  - Matrix (Slot view, user tree)
  - Referrals (Direct/Indirect referrals)
  - Transactions (Earnings, rebirths)
  - Profile (Wallet + KYC)
  - Slots (View, Buy, Upgrade)
  - Pool (Magic pool status & rewards)

---

## 🧪 Testing

```bash
# Compile contracts
npx hardhat compile

# Run backend server
cd backend
npm install
npm run dev

# Run frontend
cd fortunity-nxt-frontend
npm install
npm start
```

---

## 🧠 Concepts

- **2x2 Forced Matrix**: Each user fills 2 referrals directly, and next 4 indirectly.
- **Rebirth**: When a matrix is filled, the user cycles back and starts a new matrix.
- **Dynamic Pricing**: Uses Chainlink to price slots in CORE based on USD.
- **Level Income**: 25% distributed to 50 levels (based on directs).
- **Magic Pool**: 25% reserved for milestone-based reward days (5, 15, 25).
- **Admin Fee**: 3% cut from every payment goes to treasury.

---

## 📄 Environment Variables

```bash
# .env
DEPLOYER_PRIVATE_KEY=your_private_key
RPC_URL=https://rpc.coreblockchain.net
ETHERSCAN_API_KEY=your_etherscan_key
CHAINLINK_FEED_ADDRESS=your_chainlink_feed
```

---

## 🔗 Useful Links

- 🔸 [Diamond Standard – EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)
- 🧰 [Hardhat Documentation](https://hardhat.org/docs)
- 📚 [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

---

## 📬 Support

For technical queries or issues, please reach out via GitHub Issues on the respective repository.

---

> Project by GN TechnoCloud | FortunityNXT 2025