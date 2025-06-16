// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/AppStorageLib.sol";

contract LevelIncomeFacet {
    using AppStorageLib for AppStorageLib.AppStorage;

    /// @notice Returns the level income eligibility for a specific user
    /// @param user The wallet address to query
    /// @return levelEligibility An array of booleans for levels 1 to 50
    function getLevelEligibility(
        address user
    ) external view returns (bool[] memory levelEligibility) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        levelEligibility = new bool; // index 1–50 used

        if (!s.users[user].isActive) return levelEligibility;

        uint256 directs = s.users[user].directReferrals;
        for (uint256 i = 1; i <= 50; i++) {
            AppStorageLib.LevelRequirement memory req = s.levelRequirements[i];
            levelEligibility[i] = (directs >= req.directRequired);
        }
    }

    /// @notice Returns the complete level income configuration table
    /// @return directRequired Array of directs needed per level
    /// @return percentBasisPoints Array of reward percent (in basis points) per level
    function getLevelIncomeTable()
        external
        view
        returns (
            uint256[] memory directRequired,
            uint256[] memory percentBasisPoints
        )
    {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();

        directRequired = new uint256;
        percentBasisPoints = new uint256;

        for (uint256 i = 1; i <= 50; i++) {
            AppStorageLib.LevelRequirement memory req = s.levelRequirements[i];
            directRequired[i] = req.directRequired;
            percentBasisPoints[i] = req.percent;
        }
    }

    /// @notice Allows admin to update level income configuration
    /// @dev Only contract owner can call this function
    function updateLevelIncome(
        uint256[] calldata levels,
        uint256[] calldata directs,
        uint256[] calldata percents
    ) external {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        require(msg.sender == s.owner, "Only owner");

        require(
            levels.length == directs.length &&
                directs.length == percents.length,
            "Array length mismatch"
        );

        for (uint256 i = 0; i < levels.length; i++) {
            uint256 level = levels[i];
            require(level >= 1 && level <= 50, "Invalid level");

            s.levelRequirements[level] = AppStorageLib.LevelRequirement({
                directRequired: directs[i],
                percent: percents[i]
            });
        }
    }

    /// @notice View function for a user’s current level earnings
    function getLevelEarnings(address user) external view returns (uint256) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        return s.users[user].levelEarnings;
    }

    /// @notice Returns the upline referral chain up to 50 levels
    function getUpline(
        address user
    ) external view returns (address[] memory uplines) {
        AppStorageLib.AppStorage storage s = AppStorageLib.diamondStorage();
        uplines = new address;

        address current = s.users[user].referrer;
        for (uint256 i = 0; i < 50 && current != address(0); i++) {
            uplines[i] = current;
            current = s.users[current].referrer;
        }
    }
}
