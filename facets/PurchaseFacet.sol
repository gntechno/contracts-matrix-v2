// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/AppStorageLib.sol";
import "../libraries/MatrixLib.sol";
import "../interfaces/IPriceFeed.sol";

/**
 * @title PurchaseFacet
 * @notice Handles additional slot purchases and matrix placement.
 */
contract PurchaseFacet {
    using AppStorageLib for AppStorageLib.AppStorage;
    using MatrixLib for AppStorageLib.MatrixNode;
    using MatrixLib for AppStorageLib.User;

    event SlotPurchased(address indexed user, uint256 slotId);
    event MatrixPlaced(
        address indexed user,
        address indexed placedUnder,
        uint256 slotId
    );

    /**
     * @notice Allows an active user to purchase a new slot
     * @param _slotId The ID of the slot to purchase
     */
    function purchaseSlot(uint256 _slotId) external payable {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        address user = msg.sender;

        require(s.users[user].isActive, "User not registered");
        require(s.slots[_slotId].active, "Invalid slot");
        require(!_hasActiveSlot(s.users[user], _slotId), "Slot already active");

        // Calculate price using Chainlink
        uint256 slotPriceUSD = s.slots[_slotId].priceUSD;
        uint256 slotPriceCORE = s.priceFeed.usdToNative(slotPriceUSD);
        require(msg.value >= slotPriceCORE, "Insufficient payment");

        // Admin fee (3%)
        uint256 adminFee = (msg.value * s.ADMIN_FEE_PERCENT) / 100;
        (bool sentFee, ) = payable(s.adminWallet).call{value: adminFee}("");
        require(sentFee, "Admin fee transfer failed");

        uint256 remaining = msg.value - adminFee;
        s.totalVolume += msg.value;

        // Activate slot
        s.users[user].activeSlots.push(_slotId);

        // Matrix setup
        AppStorageLib.MatrixNode storage matrix = s.users[user].matrices[
            _slotId
        ];
        matrix.owner = user;
        matrix.createdAt = block.timestamp;

        // Matrix placement logic
        address placement = MatrixLib.findAvailableUpline(user, _slotId, s);
        uint256 levelPlaced = s.users[placement].matrices[_slotId].placeChild(
            user
        );
        require(levelPlaced > 0, "Matrix placement failed");

        s.slotParticipants[_slotId].push(user);

        emit SlotPurchased(user, _slotId);
        emit MatrixPlaced(user, placement, _slotId);
    }

    /// @notice Checks if a user already has a given slot
    function _hasActiveSlot(
        AppStorageLib.User storage user,
        uint256 slotId
    ) internal view returns (bool) {
        for (uint256 i = 0; i < user.activeSlots.length; i++) {
            if (user.activeSlots[i] == slotId) {
                return true;
            }
        }
        return false;
    }
}
// Compare this snippet from facets/UserViewFacet.sol:
