// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MatrixFacet {
    event UserRegistered(
        address indexed user,
        address indexed referrer,
        uint256 slot
    );
    event SlotPurchased(address indexed user, uint256 slot, uint256 priceCORE);
    event UserPlaced(
        address indexed user,
        uint256 slot,
        address indexed underReferrer,
        uint8 level
    );

    modifier onlyRegistered() {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        require(s.users[msg.sender].isActive, "User not registered");
        _;
    }

    function register(address referrer, uint256 slot) external {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        require(!s.users[msg.sender].isActive, "Already registered");
        require(
            s.users[referrer].isActive || referrer == s.adminWallet,
            "Invalid referrer"
        );
        require(slot > 0 && slot <= s.maxSlotLevel, "Invalid slot");

        // Price in USD
        uint256 priceUSD = s.slots[slot].priceUSD;
        require(priceUSD > 0, "Slot not priced");

        uint256 coreAmount = _getCOREAmount(s, priceUSD);
        require(
            s.token.transferFrom(msg.sender, address(this), coreAmount),
            "Payment failed"
        );

        // 3% admin fee
        uint256 adminFee = (coreAmount * 3) / 100;
        require(
            s.token.transfer(s.adminWallet, adminFee),
            "Admin fee transfer failed"
        );

        s.totalUsers++;
        s.totalVolume += coreAmount;

        AppStorageLib.User storage user = s.users[msg.sender];
        user.referrer = referrer;
        user.joinedAt = block.timestamp;
        user.isActive = true;
        user.activeSlots.push(slot);

        s.registered[msg.sender] = true;
        s.slotParticipants[slot].push(msg.sender);

        // Place in matrix
        _placeInMatrix(s, msg.sender, slot);

        // Register referral
        s.users[referrer].directReferrals++;

        emit UserRegistered(msg.sender, referrer, slot);
        emit SlotPurchased(msg.sender, slot, coreAmount);
    }

    function buySlot(uint256 slot) external onlyRegistered {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        AppStorageLib.User storage user = s.users[msg.sender];

        require(slot > 0 && slot <= s.maxSlotLevel, "Invalid slot");
        require(!_hasSlot(user, slot), "Slot already active");

        uint256 priceUSD = s.slots[slot].priceUSD;
        require(priceUSD > 0, "Slot not priced");

        uint256 coreAmount = _getCOREAmount(s, priceUSD);
        require(
            s.token.transferFrom(msg.sender, address(this), coreAmount),
            "Payment failed"
        );

        // 3% admin fee
        uint256 adminFee = (coreAmount * 3) / 100;
        require(
            s.token.transfer(s.adminWallet, adminFee),
            "Admin fee transfer failed"
        );

        s.totalVolume += coreAmount;
        user.activeSlots.push(slot);
        s.slotParticipants[slot].push(msg.sender);

        // Place in matrix
        _placeInMatrix(s, msg.sender, slot);

        emit SlotPurchased(msg.sender, slot, coreAmount);
    }

    // ----------------- Internal Utilities ----------------------

    function _placeInMatrix(
        AppStorageLib.AppStorage storage s,
        address user,
        uint256 slot
    ) internal {
        address ref = s.users[user].referrer;

        // Search for eligible referrer in matrix tree
        address placedUnder = _findAvailablePosition(s, ref, slot);
        AppStorageLib.MatrixNode storage matrix = s.users[placedUnder].matrices[
            slot
        ];

        if (matrix.level1.length < 2) {
            matrix.level1.push(user);
            emit UserPlaced(user, slot, placedUnder, 1);
        } else {
            // Place into one of level2
            address[] storage level1 = matrix.level1;
            for (uint8 i = 0; i < level1.length; i++) {
                AppStorageLib.MatrixNode storage subMatrix = s
                    .users[level1[i]]
                    .matrices[slot];
                if (subMatrix.level1.length < 2) {
                    subMatrix.level1.push(user);
                    emit UserPlaced(user, slot, level1[i], 2);
                    return;
                }
            }
            revert("No available position in matrix");
        }

        s.users[user].matrices[slot] = AppStorageLib.MatrixNode({
            owner: user,
            level1: new address[](0),
            level2: new address[](0),
            completed: false,
            earnings: 0,
            createdAt: block.timestamp
        });
    }

    function _findAvailablePosition(
        AppStorageLib.AppStorage storage s,
        address ref,
        uint256 slot
    ) internal view returns (address) {
        // If referrer's matrix is not initialized
        if (s.users[ref].matrices[slot].owner == address(0)) {
            return ref;
        }

        AppStorageLib.MatrixNode storage refMatrix = s.users[ref].matrices[
            slot
        ];
        if (refMatrix.level1.length < 2) return ref;

        for (uint8 i = 0; i < refMatrix.level1.length; i++) {
            address sub = refMatrix.level1[i];
            if (s.users[sub].matrices[slot].level1.length < 2) {
                return sub;
            }
        }

        return ref;
    }

    function _hasSlot(
        AppStorageLib.User storage user,
        uint256 slot
    ) internal view returns (bool) {
        for (uint256 i = 0; i < user.activeSlots.length; i++) {
            if (user.activeSlots[i] == slot) {
                return true;
            }
        }
        return false;
    }

    function _getCOREAmount(
        AppStorageLib.AppStorage storage s,
        uint256 usdAmount
    ) internal view returns (uint256) {
        if (s.useChainlink && address(s.priceFeed) != address(0)) {
            (, int256 price, , , ) = s.priceFeed.latestRoundData();
            require(price > 0, "Invalid price feed");
            uint256 corePrice = uint256(price); // 8 decimals
            return (usdAmount * 1e18) / (corePrice * 1e10); // adjust to 18 decimals
        } else {
            require(s.manualCOREPrice > 0, "Manual CORE price not set");
            return (usdAmount * 1e18) / s.manualCOREPrice;
        }
    }
}
