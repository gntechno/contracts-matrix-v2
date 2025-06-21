# Fortunity NXT – Modular Diamond Smart Contracts (Matrix V2)

This repository contains the modular smart contract system for **Fortunity NXT**, a 2x2 Forced Matrix-based Semi-DApp built using the [Diamond Standard (EIP-2535)](https://eips.ethereum.org/EIPS/eip-2535). The contracts are designed for high scalability, upgradability, and efficient income distribution using a layered referral structure, dynamic slot system, and off-chain level income sync.

---

## 🔗 Core Features

- **Diamond Proxy Architecture** (EIP-2535)
- **2x2 Forced Matrix** Logic (with rebirth & cycling)
- **Level Income Distribution** (up to 50 levels)
- **Chainlink Price Feed Integration** (CORE/USD slot pricing)
- **25% Pool Distribution Logic** (based on fixed days)
- **LibAppStorage** for centralized state across facets
- Gas-efficient and modular upgrades

---

## 🏗️ Contract Structure

```
contracts-matrix-v2/
├── core/
│   └── FortuneNXTDiamond.sol
│   └── FortuneNXTStorage.sol
├── facets/
│   ├── AdminFacet.sol
│   ├── RegistrationFacet.sol
│   ├── PurchaseFacet.sol
│   ├── MatrixFacet.sol
│   ├── IncomeFacet.sol
│   ├── LevelIncomeFacet.sol
│   ├── MagicPoolFacet.sol
│   ├── UserViewFacet.sol
│   └── PriceFeedFacet.sol
├── libraries/
│   ├── LibDiamond.sol
│   └── LibAppStorage.sol
├── interfaces/
│   ├── IDiamondCut.sol
│   ├── IDiamondLoupe.sol
│   └── IPriceFeed.sol
├── initializers/
│   └── DiamondInit.sol
├── helpers/
│   └── IncomeDistributor.sol
├── scripts/
│   ├── deployDiamond.js
│   ├── printFacets.js
│   ├── calculate-selectors.js
│   ├── generate-merged-abi.js
│   └── mergeAbi.js
├── abi/
│   └── FortuneNXTDiamond.json
├── test/
│   └── matrix.test.js
├── .env
├── hardhat.config.js
└── package.json
```

---

## 📖 Facet Responsibilities

| Facet               | Responsibility                                         |
| ------------------- | ------------------------------------------------------ |
| `AdminFacet`        | Owner-only functions, rescue, updates                  |
| `RegistrationFacet` | Handles user onboarding, referral tree                 |
| `PurchaseFacet`     | Slot purchases & price fetch (USD to CORE)             |
| `MatrixFacet`       | Forced Matrix logic (2x2 logic + rebirths)             |
| `IncomeFacet`       | Distributes matrix income (75%)                        |
| `LevelIncomeFacet`  | Handles 25% income across 50 levels                    |
| `MagicPoolFacet`    | Pool logic (25% pool fund → distributed every 5/15/25) |
| `UserViewFacet`     | Read-only: profile, tree, slot history                 |
| `PriceFeedFacet`    | Chainlink CORE/USD price fetch + fallback              |

---

## 📊 Income Breakdown

| Component              | Allocation               |
| ---------------------- | ------------------------ |
| Admin Fee              | 3%                       |
| Matrix Income          | 75%                      |
| Level Income           | 25%                      |
| Max Payout             | 200%                     |
| Pool Distribution Days | 5, 15, 25 of every month |

---

## 🧩 Diamond Design Pattern

All facets share `LibAppStorage.sol`, which centralizes all state under one slot. Do **not** modify individual facet state. Always interact via storage pointers:

```solidity
AppStorage storage s = LibAppStorage.diamondStorage();
```

---

## 🧾 Requirements

- Node.js >= 18.x
- Hardhat >= 2.20.0
- Ethers.js v6.x (Toolbox compatible)
- CORE token (ERC20-compatible)
- Chainlink Aggregator on target network

---

## 🚀 Setup Instructions

### 1. Install Dependencies

```bash
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox dotenv
```

### 2. Compile Contracts

```bash
npx hardhat compile
```

---

## 🛠️ Deployment Guide

1. Create a `.env` file in root:

   ```ini
   DEPLOYER_PRIVATE_KEY=your_private_key_here
   RPC_URL=https://your-core-chain-rpc
   NETWORK=localhost
   CORE_TOKEN_ADDRESS=0xYourCoreToken
   CHAINLINK_PRICE_FEED=0xYourAggregator
   ```

2. Deploy contracts:

   ```bash
   npx hardhat run scripts/deployDiamond.js --network localhost
   ```

3. Print deployed facets and selectors:

   ```bash
   npx hardhat run scripts/printFacets.js --network localhost
   ```

---

## 🧪 Testing

- Use local Hardhat node to register users and simulate flows.
- Example test: `test/matrix.test.js`

```js
describe("Register 102 Users in Linear Chain", async () => {
  for (let i = 0; i < 102; i++) {
    // Register i-th user referred by (i-1)
  }
});
```

Run all tests:

```bash
npx hardhat test
```

---

## 📂 Suggested Folder Best Practices

- `lib/` for off-chain calculations and helper libraries
- `shared/` for modifiers and shared logic
- `test/` contains full flow test: registration → purchase → income → rebirth

---

## 📌 Useful Hardhat Commands

```bash
npx hardhat clean
npx hardhat test
npx hardhat run scripts/deployDiamond.js --network localhost
```

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

- [Diamond Standard – EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)
- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

---

## 🔐 License

This project is licensed under MIT. Use freely but retain attribution.

---

## ✉️ Contact

For support, reach out via GitHub [issues](https://github.com/gntechno/contracts-matrix-v2/issues) or your project lead.

---
