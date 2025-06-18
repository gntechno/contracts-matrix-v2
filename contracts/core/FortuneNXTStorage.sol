// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IPriceFeed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FortuneNXTStorage (Matrix V2 Final Version)
/// @notice Shared storage structure used by all Diamond facets
contract FortuneNXTStorage {
    // Constants
    uint256 public constant ADMIN_FEE_PERCENT = 3; // 3% admin fee
    uint256 public constant MATRIX_INCOME_PERCENT = 75; // 75% of slot goes to matrix
    uint256 public constant LEVEL_INCOME_PERCENT = 25; // 25% goes to level incomes
    uint256 public constant POOL_EXTRA_PERCENT = 25; // 25% extra over slot for pools
    uint256 public constant MAX_PAYOUT_PERCENT = 200; // 2x ROI cap
    uint256 public constant MAX_PAYOUT_TIME = 90 days;

    IERC20 token;

    // --- Core Structs ---

    struct Slot {
        uint256 priceUSD; // slot price in USD (18 decimals)
        uint256 poolPercent; // percentage going to pool (out of 10000)
        bool active;
    }

    struct MatrixNode {
        address owner;
        address[] level1; // max 2 users
        address[] level2; // max 4 users
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
        uint256[] activeSlots; // e.g. [1, 2, 3]
        mapping(uint256 => MatrixNode) matrices; // slot => matrix node
    }

    struct LevelRequirement {
        uint256 directRequired;
        uint256 percent; // basis points, 10000 = 100%
    }

    // --- Storage Variables ---

    mapping(address => User) internal users;
    mapping(uint256 => Slot) internal slots;
    mapping(uint256 => LevelRequirement) internal levelRequirements;
    mapping(uint256 => address[]) internal slotParticipants;
    mapping(uint256 => uint256) internal poolBalances;

    address public owner;
    address public treasury;
    address public adminWallet; // Admin fee & fallback receiver

    uint256 public totalUsers;
    uint256 public totalVolume;
    uint256 public totalPoolBalance;
    uint256 public lastPoolDistributionTime;

    uint8[3] public poolDistributionDays = [5, 15, 25];
    uint256 public version;

    IPriceFeed public priceFeed;

    // --- Upgradeable Gap ---
    uint256[48] private __gap; // Adjusted for new adminWallet
}
