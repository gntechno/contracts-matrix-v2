// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../interfaces/IPriceFeed.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library AppStorageLib {
    // Constants

    uint256 constant ADMIN_FEE_PERCENT = 3;

    uint256 constant MATRIX_INCOME_PERCENT = 75;

    uint256 constant LEVEL_INCOME_PERCENT = 25;

    uint256 constant POOL_EXTRA_PERCENT = 25;

    uint256 constant MAX_PAYOUT_PERCENT = 200;

    uint256 constant MAX_PAYOUT_TIME = 90 days;

    struct MatrixNode {
        address owner;
        address[] level1;
        address[] level2;
        bool completed;
        uint256 earnings;
        uint256 createdAt;
    }

    struct User {
        address referrer;
        uint256 joinedAt;
        bool isActive;
        uint256 directReferrals;
        uint256 totalEarnings;
        uint256 matrixEarnings;
        uint256 levelEarnings;
        uint256 poolEarnings;
        uint256 lastPoolDistribution;
        uint256[] activeSlots;
        mapping(uint256 => MatrixNode) matrices;
    }

    struct Slot {
        uint256 priceUSD;
        uint256 poolPercent;
        bool active;
    }

    struct LevelRequirement {
        uint256 directRequired;
        uint256 percent; // out of 10000 (basis points)
    }

    struct AppStorage {
        // Core components
        mapping(address => bool) adminRoles; // ✅ Add this line
        bool useChainlink;
        IERC20 token;
        IPriceFeed priceFeed;
        uint256 manualCOREPrice;
        uint256 maxSlotLevel; // Maximum allowed slot index
        mapping(address => User) users;
        mapping(uint256 => Slot) slots;
        mapping(uint256 => LevelRequirement) levelRequirements;
        mapping(uint256 => address[]) slotParticipants;
        mapping(uint256 => uint256) poolBalances;
        mapping(address => bool) registered;
        address owner;
        address treasury;
        address adminWallet;
        uint256 totalUsers;
        uint256 totalVolume;
        uint256 totalPoolBalance;
        uint256 lastPoolDistributionTime;
        uint8[3] poolDistributionDays;
        uint256 version;
    }

    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("fortunity.nxt.diamond.storage");

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }
}
