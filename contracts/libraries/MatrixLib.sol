// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AppStorageLib} from "../libraries/LibAppStorage.sol";

/**
 * @title MatrixLib
 * @dev Utility library for matrix-related logic in Fortunity NXT
 */
library MatrixLib {
    using MatrixLib for AppStorageLib.MatrixNode;

    /**
     * @dev Check if a user has an active slot
     */
    function hasActiveSlot(
        AppStorageLib.User storage user,
        uint256 slotId
    ) internal view returns (bool) {
        for (uint8 i = 0; i < user.activeSlots.length; i++) {
            if (user.activeSlots[i] == slotId) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Check if a matrix node is complete (2 on level 1, 4 on level 2)
     */
    function isMatrixComplete(
        AppStorageLib.MatrixNode storage matrix
    ) internal view returns (bool) {
        return matrix.level1.length == 2 && matrix.level2.length == 4;
    }

    /**
     * @dev Count total referrals across both levels
     */
    function totalReferrals(
        AppStorageLib.MatrixNode storage matrix
    ) internal view returns (uint8) {
        return uint8(matrix.level1.length + matrix.level2.length);
    }

    /**
     * @dev Attempt to place a child into matrix
     * Returns: level placed (1 or 2), or 0 if not placed
     */
    function placeChild(
        AppStorageLib.MatrixNode storage matrix,
        address child
    ) internal returns (uint8) {
        if (matrix.level1.length < 2) {
            matrix.level1.push(child);
            return 1;
        } else if (matrix.level2.length < 4) {
            matrix.level2.push(child);
            return 2;
        }
        return 0;
    }
    // Add this function if it does not exist or make it public

    // ✅ This is the missing function causing your error
    function findAvailableUpline(
        address user,
        uint256 slotId,
        AppStorageLib.AppStorage storage s
    ) internal view returns (address) {
        address referrer = s.users[user].referrer;

        if (
            referrer != address(0) &&
            hasActiveSlot(s.users[referrer], slotId) &&
            !isMatrixComplete(s.users[referrer].matrices[slotId])
        ) {
            return referrer;
        }

        address[] storage participants = s.slotParticipants[slotId];
        for (uint256 i = 0; i < participants.length; i++) {
            address candidate = participants[i];
            if (!isMatrixComplete(s.users[candidate].matrices[slotId])) {
                return candidate;
            }
        }

        return s.owner;
    }
    /**
     * @dev Find available position in matrix for a user
     * Returns: address of the placement
     */
    function findAvailablePosition(
        AppStorageLib.AppStorage storage s,
        address user,
        uint8 slotId
    ) internal view returns (address) {
        address referrer = s.users[user].referrer;

        // If referrer is not active or has no matrix, return owner
        if (
            referrer == address(0) ||
            !s.users[referrer].isActive ||
            !hasActiveSlot(s.users[referrer], slotId)
        ) {
            return s.owner;
        }

        AppStorageLib.MatrixNode storage refMatrix = s.users[referrer].matrices[
            slotId
        ];

        // Check level 1 first
        if (refMatrix.level1.length < 2) {
            return referrer;
        }

        // Check level 2
        for (uint8 i = 0; i < refMatrix.level1.length; i++) {
            AppStorageLib.MatrixNode storage subMatrix = s
                .users[refMatrix.level1[i]]
                .matrices[slotId];
            if (subMatrix.level1.length < 2) {
                return refMatrix.level1[i];
            }
        }

        // If all full, return owner
        return s.owner;
    }
}
