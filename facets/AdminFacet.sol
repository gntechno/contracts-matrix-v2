// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "../lib/AppStorageLib.sol";
import "../interfaces/IPriceFeed.sol";

/**
 * @title AdminFacet
 * @notice Administrative control for FortuneNXT with Diamond Standard storage.
 */
contract AdminFacet is AccessControlEnumerable {
    using AppStorageLib for AppStorageLib.AppStorage;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event AdminFeePaid(uint256 amount);
    event TreasuryUpdated(
        address indexed oldTreasury,
        address indexed newTreasury
    );
    event SlotUpdated(
        uint256 indexed slotNumber,
        uint256 priceUSD,
        uint256 poolPercent
    );
    event SlotActiveStatusChanged(uint256 indexed slotNumber, bool active);
    event PoolDistributionDaysUpdated(uint8[3] distributionDays);
    event LevelRequirementUpdated(
        uint256 indexed level,
        uint256 directRequired,
        uint256 percent
    );
    event PriceFeedUpdated(address indexed newPriceFeed);

    // -------------------------
    // Admin Setup & Management
    // -------------------------

    function initializeAdminFacet(address admin) external {
        require(admin != address(0), "Invalid admin address");

        bool isInitialSetup = getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0;

        if (isInitialSetup) {
            _grantRole(DEFAULT_ADMIN_ROLE, admin);
            _grantRole(ADMIN_ROLE, admin);
        } else {
            require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized");
            require(!hasRole(DEFAULT_ADMIN_ROLE, admin), "Already admin");

            grantRole(DEFAULT_ADMIN_ROLE, admin);
            grantRole(ADMIN_ROLE, admin);
        }
    }

    function grantAdminRole(
        address _newAdmin
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newAdmin != address(0), "Invalid address");
        grantRole(ADMIN_ROLE, _newAdmin);
    }

    function revokeAdminRole(
        address _admin
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_admin != address(0), "Invalid address");
        revokeRole(ADMIN_ROLE, _admin);
    }

    // -------------------------
    // Slot Management
    // -------------------------

    function updateSlot(
        uint256 _slotNumber,
        uint256 _priceUSD,
        uint256 _poolPercent
    ) external onlyRole(ADMIN_ROLE) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        require(_slotNumber >= 1 && _slotNumber <= 12, "Invalid slot");
        require(_priceUSD > 0, "Invalid price");
        require(_poolPercent <= 100, "Invalid pool %");

        s.slots[_slotNumber].priceUSD = _priceUSD;
        s.slots[_slotNumber].poolPercent = _poolPercent;

        emit SlotUpdated(_slotNumber, _priceUSD, _poolPercent);
    }

    function setSlotActive(
        uint256 _slotNumber,
        bool _active
    ) external onlyRole(ADMIN_ROLE) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        require(_slotNumber >= 1 && _slotNumber <= 12, "Invalid slot");
        s.slots[_slotNumber].active = _active;
        emit SlotActiveStatusChanged(_slotNumber, _active);
    }

    // -------------------------
    // Treasury & Fees
    // -------------------------

    function setTreasury(address _newTreasury) external onlyRole(ADMIN_ROLE) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        require(_newTreasury != address(0), "Invalid address");

        address oldTreasury = s.adminWallet;
        s.adminWallet = _newTreasury;
        emit TreasuryUpdated(oldTreasury, _newTreasury);
    }

    function emergencyWithdraw(
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        require(_amount <= address(this).balance, "Insufficient balance");
        require(s.owner != address(0), "Owner not set");

        payable(s.owner).transfer(_amount);
    }

    // -------------------------
    // Level Income Config
    // -------------------------

    function updateLevelRequirement(
        uint256 _level,
        uint256 _directRequired,
        uint256 _percent
    ) external onlyRole(ADMIN_ROLE) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        require(_level >= 1 && _level <= 50, "Invalid level");

        s.levelRequirements[_level].directRequired = _directRequired;
        s.levelRequirements[_level].percent = _percent;

        emit LevelRequirementUpdated(_level, _directRequired, _percent);
    }

    function setPoolDistributionDays(
        uint8[3] memory _days
    ) external onlyRole(ADMIN_ROLE) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        for (uint8 i = 0; i < 3; i++) {
            require(_days[i] >= 1 && _days[i] <= 30, "Invalid day");
        }
        s.poolDistributionDays = _days;
        emit PoolDistributionDaysUpdated(_days);
    }

    function setPriceFeed(address _priceFeed) external onlyRole(ADMIN_ROLE) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        require(_priceFeed != address(0), "Invalid address");
        s.priceFeed = IPriceFeed(_priceFeed);
        emit PriceFeedUpdated(_priceFeed);
    }

    // -------------------------
    // READ-ONLY Getters
    // -------------------------

    function getSlot(
        uint256 _slotId
    ) external view returns (AppStorageLib.Slot memory) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        return s.slots[_slotId];
    }

    function getPriceFeed() external view returns (address) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        return address(s.priceFeed);
    }

    function isAdmin(address _account) external view returns (bool) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        return s.adminRoles[_account];
    }

    function getOwner() external view returns (address) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        return s.owner;
    }

    function getAdminWallet() external view returns (address) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        return s.adminWallet;
    }

    function getLevelRequirement(
        uint256 _level
    ) external view returns (uint256 directRequired, uint256 percent) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        AppStorageLib.LevelRequirement storage req = s.levelRequirements[
            _level
        ];
        return (req.directRequired, req.percent);
    }

    function getPoolDistributionDays() external view returns (uint8[3] memory) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        return s.poolDistributionDays;
    }
}
