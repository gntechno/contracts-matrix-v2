// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/AppStorageLib.sol";

contract UserViewFacet {
    using AppStorageLib for AppStorageLib.AppStorage;

    struct UserProfile {
        address referrer;
        uint256 joinedAt;
        bool isActive;
        uint256 directReferrals;
        uint256 totalEarnings;
        uint256 matrixEarnings;
        uint256 levelEarnings;
        uint256 poolEarnings;
        uint256[] activeSlots;
    }

    struct MatrixNodeView {
        address owner;
        address[] level1;
        address[] level2;
        bool completed;
        uint256 earnings;
        uint256 createdAt;
    }

    /// @notice Returns basic profile information of a user
    function getUserProfile(
        address user
    ) external view returns (UserProfile memory profile) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        AppStorageLib.User storage u = s.users[user];

        profile = UserProfile({
            referrer: u.referrer,
            joinedAt: u.joinedAt,
            isActive: u.isActive,
            directReferrals: u.directReferrals,
            totalEarnings: u.totalEarnings,
            matrixEarnings: u.matrixEarnings,
            levelEarnings: u.levelEarnings,
            poolEarnings: u.poolEarnings,
            activeSlots: u.activeSlots
        });
    }

    /// @notice Returns matrix node info of a user for a specific slot
    function getMatrixNode(
        address user,
        uint256 slot
    ) external view returns (MatrixNodeView memory node) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        AppStorageLib.MatrixNode storage m = s.users[user].matrices[slot];

        node = MatrixNodeView({
            owner: m.owner,
            level1: m.level1,
            level2: m.level2,
            completed: m.completed,
            earnings: m.earnings,
            createdAt: m.createdAt
        });
    }

    /// @notice Returns all active users in a particular slot
    function getSlotParticipants(
        uint256 slot
    ) external view returns (address[] memory) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        return s.slotParticipants[slot];
    }

    /// @notice Returns whether a given user has a specific slot active
    function hasActiveSlot(
        address user,
        uint256 slot
    ) external view returns (bool) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        AppStorageLib.User storage u = s.users[user];

        for (uint256 i = 0; i < u.activeSlots.length; i++) {
            if (u.activeSlots[i] == slot) return true;
        }

        return false;
    }

    /// @notice Returns the current owner of a matrix slot
    function getMatrixOwner(
        address user,
        uint256 slot
    ) external view returns (address) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        return s.users[user].matrices[slot].owner;
    }

    /// @notice Returns how many total users are in the system
    function getTotalUsers() external view returns (uint256) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        return s.totalUsers;
    }

    /// @notice Returns system-wide statistics
    function getGlobalStats()
        external
        view
        returns (
            uint256 totalUsers,
            uint256 totalVolume,
            uint256 totalPoolBalance,
            uint256 lastPoolDistributionTime
        )
    {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        return (
            s.totalUsers,
            s.totalVolume,
            s.totalPoolBalance,
            s.lastPoolDistributionTime
        );
    }
}
