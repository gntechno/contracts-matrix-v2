// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/FortuneNXTStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library IncomeDistributor {
    event IncomeDistributed(
        address indexed to,
        uint256 amount,
        string incomeType
    );
    event AdminFeeTaken(
        address indexed adminWallet,
        uint256 feeAmount,
        string incomeType
    );
    event UndistributedRedirected(
        address indexed fallbackAddress,
        uint256 amount,
        string incomeType
    );

    function distributeIncome(
        address user,
        uint256 amount,
        string memory incomeType,
        address token,
        address adminWallet
    ) internal {
        require(amount > 0, "Zero amount");

        uint256 fee = (amount * 3) / 100;
        uint256 netAmount = amount - fee;

        // Transfer fee to admin
        IERC20(token).transfer(adminWallet, fee);
        emit AdminFeeTaken(adminWallet, fee, incomeType);

        // Transfer income to user
        IERC20(token).transfer(user, netAmount);
        emit IncomeDistributed(user, netAmount, incomeType);
    }

    function redirectUndistributed(
        uint256 amount,
        string memory incomeType,
        address token,
        address adminWallet
    ) internal {
        require(amount > 0, "Zero undistributed income");

        IERC20(token).transfer(adminWallet, amount);
        emit UndistributedRedirected(adminWallet, amount, incomeType);
    }
}
