// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/AppStorageLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MagicPoolFacet {
    using AppStorageLib for AppStorageLib.AppStorage;

    event PoolFunded(
        uint256 indexed slot,
        uint256 amount,
        address indexed from
    );
    event PoolDistributed(
        uint256 indexed slot,
        uint256 amountPerUser,
        uint256 totalUsers
    );
    event PoolAdminFeeTaken(uint256 indexed slot, uint256 feeAmount);

    uint256 public constant ADMIN_FEE_PERCENT = 3;
    uint256 public constant POOL_EXTRA_PERCENT = 25;

    function fundPool(uint256 slot) external {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        require(s.slots[slot].active, "Slot not active");

        uint256 usdAmount = s.slots[slot].priceUSD;
        uint256 coreAmount = _getCOREAmount(
            s,
            (usdAmount * POOL_EXTRA_PERCENT) / 100
        );
        require(
            s.token.transferFrom(msg.sender, address(this), coreAmount),
            "Transfer failed"
        );

        s.poolBalances[slot] += coreAmount;
        s.totalPoolBalance += coreAmount;

        emit PoolFunded(slot, coreAmount, msg.sender);
    }

    function distributePool(uint256 slot) external {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();

        // Enforce date: 5th, 15th, 25th only
        uint8 day = _getDayOfMonth(block.timestamp);
        require(_isValidPoolDay(s, day), "Invalid pool distribution day");

        address[] storage participants = s.slotParticipants[slot];
        require(participants.length > 0, "No participants");

        uint256 balance = s.poolBalances[slot];
        require(balance > 0, "Nothing to distribute");

        uint256 adminFee = (balance * ADMIN_FEE_PERCENT) / 100;
        uint256 distributable = balance - adminFee;
        uint256 amountPerUser = distributable / participants.length;

        for (uint256 i = 0; i < participants.length; i++) {
            require(
                s.token.transfer(participants[i], amountPerUser),
                "Payout failed"
            );
            s.users[participants[i]].poolEarnings += amountPerUser;
            s.users[participants[i]].totalEarnings += amountPerUser;
        }

        require(s.token.transfer(s.adminWallet, adminFee), "Admin fee failed");

        emit PoolDistributed(slot, amountPerUser, participants.length);
        emit PoolAdminFeeTaken(slot, adminFee);

        s.poolBalances[slot] = 0;
        s.lastPoolDistributionTime = block.timestamp;
    }

    function getPoolInfo(
        uint256 slot
    )
        external
        view
        returns (
            uint256 balance,
            uint256 participantCount,
            uint256 lastDistributed
        )
    {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        balance = s.poolBalances[slot];
        participantCount = s.slotParticipants[slot].length;
        lastDistributed = s.lastPoolDistributionTime;
    }

    function _getCOREAmount(
        AppStorageLib.AppStorage storage s,
        uint256 usdAmount
    ) internal view returns (uint256) {
        if (s.useChainlink && address(s.priceFeed) != address(0)) {
            (, int256 price, , , ) = s.priceFeed.latestRoundData();
            require(price > 0, "Invalid price feed");
            return (usdAmount * 1e18) / (uint256(price) * 1e10); // 8 decimals price → 18 decimals CORE
        } else {
            require(s.manualCOREPrice > 0, "Manual price required");
            return (usdAmount * 1e18) / s.manualCOREPrice;
        }
    }

    function _getDayOfMonth(uint256 timestamp) internal pure returns (uint8) {
        // Crude day approximation assuming 30-day months
        return uint8(((timestamp / 86400) % 30) + 1);
    }

    function _isValidPoolDay(
        AppStorageLib.AppStorage storage s,
        uint8 day
    ) internal view returns (bool) {
        for (uint256 i = 0; i < s.poolDistributionDays.length; i++) {
            if (s.poolDistributionDays[i] == day) {
                return true;
            }
        }
        return false;
    }
}
