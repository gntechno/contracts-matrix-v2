// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/AppStorageLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IncomeFacet {
    event MatrixPayout(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 slot
    );
    event LevelPayout(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 level
    );

    uint256 public constant MATRIX_PERCENT = 75; // 75% to matrix
    uint256 public constant LEVEL_PERCENT = 25; // 25% to level income
    uint256 public constant ADMIN_FEE_PERCENT = 3; // 3% deduction

    function distributeIncome(address user, uint256 slot) external {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        require(s.users[user].isActive, "User not active");
        require(_hasSlot(s.users[user], slot), "Slot not active");

        uint256 priceUSD = s.slots[slot].priceUSD;
        uint256 coreAmount = _getCOREAmount(s, priceUSD);

        uint256 matrixPortion = (coreAmount * MATRIX_PERCENT) / 100;
        uint256 levelPortion = (coreAmount * LEVEL_PERCENT) / 100;

        _payMatrix(s, user, slot, matrixPortion);
        _payLevelIncome(s, user, levelPortion);
    }

    function _payMatrix(
        AppStorageLib.AppStorage storage s,
        address user,
        uint256 slot,
        uint256 amount
    ) internal {
        address ref = s.users[user].referrer;
        address receiver = _findMatrixUpline(s, ref, slot);

        if (receiver == address(0)) {
            receiver = s.adminWallet;
        }

        uint256 adminCut = (amount * ADMIN_FEE_PERCENT) / 100;
        uint256 netAmount = amount - adminCut;

        require(s.token.transfer(receiver, netAmount), "Matrix payout failed");
        require(s.token.transfer(s.adminWallet, adminCut), "Admin fee failed");

        s.users[receiver].matrixEarnings += netAmount;
        s.users[receiver].totalEarnings += netAmount;

        emit MatrixPayout(user, receiver, netAmount, slot);
    }

    function _payLevelIncome(
        AppStorageLib.AppStorage storage s,
        address user,
        uint256 totalAmount
    ) internal {
        address ref = s.users[user].referrer;
        for (uint256 level = 1; level <= 50; level++) {
            if (ref == address(0)) break;

            AppStorageLib.User storage upline = s.users[ref];
            AppStorageLib.LevelRequirement memory req = s.levelRequirements[
                level
            ];

            if (
                req.percent > 0 &&
                upline.directReferrals >= req.directRequired &&
                upline.isActive
            ) {
                uint256 amount = (totalAmount * req.percent) / 10000;
                uint256 adminCut = (amount * ADMIN_FEE_PERCENT) / 100;
                uint256 netAmount = amount - adminCut;

                require(
                    s.token.transfer(ref, netAmount),
                    "Level payout failed"
                );
                require(
                    s.token.transfer(s.adminWallet, adminCut),
                    "Admin fee failed"
                );

                upline.levelEarnings += netAmount;
                upline.totalEarnings += netAmount;

                emit LevelPayout(user, ref, netAmount, level);
            }

            ref = upline.referrer;
        }
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

    function _findMatrixUpline(
        AppStorageLib.AppStorage storage s,
        address referrer,
        uint256 slot
    ) internal view returns (address) {
        // Traverse matrix to find someone with slot active
        while (referrer != address(0)) {
            if (_hasSlot(s.users[referrer], slot)) {
                return referrer;
            }
            referrer = s.users[referrer].referrer;
        }
        return address(0);
    }

    function _hasSlot(
        AppStorageLib.User storage user,
        uint256 slot
    ) internal view returns (bool) {
        for (uint256 i = 0; i < user.activeSlots.length; i++) {
            if (user.activeSlots[i] == slot) return true;
        }
        return false;
    }
}
// Note: This code assumes that the AppStorageLib and User structures are defined
// in the AppStorageLib library, and that the necessary imports and configurations are set up correctly.
