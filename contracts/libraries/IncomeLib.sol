// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IncomeLib
/// @notice Handles all income distribution logic with admin fee and fallback redirection
library IncomeLib {
    uint256 internal constant ADMIN_FEE_PERCENT = 3;

    /// @notice Safely distributes income to a user with 3% admin fee deduction
    /// @param recipient The user receiving net income
    /// @param amount Total amount to be distributed
    /// @param adminWallet The fallback wallet receiving the 3% fee
    function distributeWithAdminFee(
        address payable recipient,
        uint256 amount,
        address payable adminWallet
    ) internal {
        require(amount > 0, "Zero amount");

        uint256 adminFee = (amount * ADMIN_FEE_PERCENT) / 100;
        uint256 netAmount = amount - adminFee;

        // Send net amount to user
        (bool userSent, ) = recipient.call{value: netAmount}("");
        require(userSent, "Payout to user failed");

        // Send admin fee
        (bool adminSent, ) = adminWallet.call{value: adminFee}("");
        require(adminSent, "Admin fee transfer failed");
    }

    /// @notice Redirects entire income to a fallback wallet (for unqualified uplines)
    /// @param amount Total undistributed amount
    /// @param fallbackWallet The designated fallback address
    function redirectToFallback(
        uint256 amount,
        address payable fallbackWallet
    ) internal {
        require(amount > 0, "Zero amount to redirect");

        (bool sent, ) = fallbackWallet.call{value: amount}("");
        require(sent, "Redirect to fallback failed");
    }
}
