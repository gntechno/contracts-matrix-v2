// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPriceFeed {
    function getLatestPrice() external view returns (uint256);
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
    /// @notice Converts USD value to native blockchain token value (e.g., CORE)
    function usdToNative(uint256 usdAmount) external view returns (uint256);
    /// @notice Converts native blockchain token value (e.g., CORE) to USD value
    function nativeToUsd(uint256 nativeAmount) external view returns (uint256);
    /// @notice Updates the price feed with the latest data
}
