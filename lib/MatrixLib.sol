// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FortuneNXTStorage} from "../core/FortuneNXTStorage.sol";

/**
 * @title MatrixLib
 * @dev Utility library for matrix-related logic in Fortunity NXT
 */
library MatrixLib {
    using MatrixLib for FortuneNXTStorage.MatrixNode;

    /**
     * @dev Check if a user has an active slot
     */
    function hasActiveSlot(
        FortuneNXTStorage.User storage user,
        uint8 slotId
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
        FortuneNXTStorage.MatrixNode storage matrix
    ) internal view returns (bool) {
        return matrix.level1.length == 2 && matrix.level2.length == 4;
    }

    /**
     * @dev Count total referrals across both levels
     */
    function totalReferrals(
        FortuneNXTStorage.MatrixNode storage matrix
    ) internal view returns (uint8) {
        return uint8(matrix.level1.length + matrix.level2.length);
    }

    /**
     * @dev Attempt to place a child into matrix
     * Returns: level placed (1 or 2), or 0 if not placed
     */
    function placeChild(
        FortuneNXTStorage.MatrixNode storage matrix,
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

    /**
     * @dev Get available upline who has space in their matrix
     * Priority: Referrer → Global participants → Owner
     */
    function findAvailableUpline(
        address user,
        uint8 slotId,
        FortuneNXTStorage.Layout storage ds
    ) internal view returns (address) {
        address referrer = ds.users[user].referrer;

        if (
            referrer != address(0) && hasActiveSlot(ds.users[referrer], slotId)
        ) {
            if (!isMatrixComplete(ds.users[referrer].matrices[slotId])) {
                return referrer;
            }
        }

        address[] storage participants = ds.slotParticipants[slotId];
        for (uint256 i = 0; i < participants.length; i++) {
            address candidate = participants[i];
            if (!isMatrixComplete(ds.users[candidate].matrices[slotId])) {
                return candidate;
            }
        }

        return ds.owner; // fallback
    }
}
