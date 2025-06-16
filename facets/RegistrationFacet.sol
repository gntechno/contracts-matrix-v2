// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/AppStorageLib.sol";
import "../libraries/MatrixLib.sol";
import "../interfaces/IPriceFeed.sol";

contract RegistrationFacet {
    using AppStorageLib for AppStorageLib.AppStorage;
    using MatrixLib for AppStorageLib.MatrixNode;
    using MatrixLib for AppStorageLib.User;

    event UserRegistered(
        address indexed user,
        address indexed referrer,
        uint256 slot
    );
    event MatrixPlaced(
        address indexed user,
        address indexed placedUnder,
        uint256 slot
    );

    /// @notice Register a user into the system with a referrer and a given slot
    function register(address _referrer, uint256 _slotId) external payable {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        address user = msg.sender;

        require(!s.users[user].isActive, "Already registered");
        require(
            _referrer != address(0) && _referrer != user,
            "Invalid referrer"
        );
        require(
            s.users[_referrer].isActive || _referrer == s.owner,
            "Referrer inactive"
        );
        require(s.slots[_slotId].active, "Invalid slot");

        // Chainlink conversion: USD -> CORE native currency
        uint256 slotPriceUSD = s.slots[_slotId].priceUSD; // e.g. $10 = 10 * 1e18
        uint256 slotPriceCORE = s.priceFeed.usdToNative(slotPriceUSD);
        require(msg.value >= slotPriceCORE, "Insufficient CORE sent");

        // Admin fee deduction (3%)
        uint256 adminFee = (msg.value * s.ADMIN_FEE_PERCENT) / 100;
        (bool feeSent, ) = payable(s.adminWallet).call{value: adminFee}("");
        require(feeSent, "Admin fee transfer failed");

        uint256 remaining = msg.value - adminFee;
        s.totalVolume += msg.value;

        // Register user
        AppStorageLib.User storage newUser = s.users[user];
        newUser.isActive = true;
        newUser.referrer = _referrer;
        newUser.joinedAt = block.timestamp;
        newUser.activeSlots.push(_slotId);
        s.users[_referrer].directReferrals++;
        s.totalUsers++;

        // Matrix setup
        AppStorageLib.MatrixNode storage matrix = newUser.matrices[_slotId];
        matrix.owner = user;
        matrix.createdAt = block.timestamp;

        // Matrix placement logic
        address placement = MatrixLib.findAvailableUpline(user, _slotId, s);
        uint256 levelPlaced = s.users[placement].matrices[_slotId].placeChild(
            user
        );
        require(levelPlaced > 0, "Matrix placement failed");

        s.slotParticipants[_slotId].push(user);

        emit UserRegistered(user, _referrer, _slotId);
        emit MatrixPlaced(user, placement, _slotId);
    }
}
