// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title PriceFeedFacet
 * @notice Handles dynamic CORE/USD pricing for slot purchases in Fortunity NXT
 */
contract PriceFeedFacet {
    bytes32 internal constant PRICE_FEED_STORAGE_POSITION = keccak256("fortunity.nxt.pricefeed.storage");

    struct PriceFeedStorage {
        AggregatorV3Interface corePriceFeed;
        uint256[12] slotPricesUSD; // USD prices (8 decimals)
        uint256 priceUpdateInterval;
        uint256 lastPriceUpdate;
        uint256 cachedCorePrice; // 8 decimals
        bool dynamicPricingEnabled;
        address priceFeedAdmin;
    }

    function ps() internal pure returns (PriceFeedStorage storage ds) {
        bytes32 position = PRICE_FEED_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // Events
    event PriceUpdated(uint256 newPrice, uint256 timestamp);
    event SlotPriceUpdated(uint256 slotId, uint256 newCorePrice, uint256 usdPrice);
    event DynamicPricingToggled(bool enabled);

    // Modifiers
    modifier onlyPriceFeedAdmin() {
        require(msg.sender == ps().priceFeedAdmin, "Not price feed admin");
        _;
    }

    // Initialization
    function initializePriceFeed(address _corePriceFeed, address _admin) external {
        PriceFeedStorage storage ds = ps();
        require(ds.priceFeedAdmin == address(0), "Already initialized");

        ds.corePriceFeed = AggregatorV3Interface(_corePriceFeed);
        ds.priceFeedAdmin = _admin;
        ds.priceUpdateInterval = 300;
        ds.dynamicPricingEnabled = true;

        ds.slotPricesUSD = [
            uint256(5 * 10**8),
            10 * 10**8,
            20 * 10**8,
            40 * 10**8,
            80 * 10**8,
            160 * 10**8,
            320 * 10**8,
            640 * 10**8,
            1280 * 10**8,
            2560 * 10**8,
            5120 * 10**8,
            10240 * 10**8
        ];

        _updateCorePrice();
    }

    // Core Chainlink Logic
    function getCurrentCorePrice() public view returns (uint256) {
        PriceFeedStorage storage ds = ps();

        if (!ds.dynamicPricingEnabled) {
            return ds.cachedCorePrice;
        }

        try ds.corePriceFeed.latestRoundData() returns (
            uint80, int256 answer, , uint256 updatedAt, 
        ) {
            require(answer > 0, "Invalid price");
            require(block.timestamp - updatedAt < 3600, "Stale price");
            return uint256(answer);
        } catch {
            return ds.cachedCorePrice;
        }
    }

    function updateCorePrice() external {
        _updateCorePrice();
    }

    function _updateCorePrice() internal {
        PriceFeedStorage storage ds = ps();

        if (block.timestamp - ds.lastPriceUpdate < ds.priceUpdateInterval) return;

        uint256 price = getCurrentCorePrice();
        ds.cachedCorePrice = price;
        ds.lastPriceUpdate = block.timestamp;

        emit PriceUpdated(price, block.timestamp);
    }

    // Slot Pricing
    function getSlotPriceInCore(uint256 slotId) public view returns (uint256) {
        require(slotId >= 1 && slotId <= 12, "Invalid slot");
        PriceFeedStorage storage ds = ps();

        uint256 priceUSD = ds.slotPricesUSD[slotId - 1];
        uint256 corePrice = getCurrentCorePrice();
        require(corePrice > 0, "Invalid CORE price");

        return (priceUSD * 1e18) / corePrice;
    }

    function getSlotPriceInUSD(uint256 slotId) external view returns (uint256) {
        require(slotId >= 1 && slotId <= 12, "Invalid slot");
        return ps().slotPricesUSD[slotId - 1];
    }

    function getAllSlotPricesInCore() external view returns (uint256[12] memory prices) {
        for (uint256 i = 1; i <= 12; i++) {
            prices[i - 1] = getSlotPriceInCore(i);
        }
    }

    function getAllSlotPricesInUSD() external view returns (uint256[12] memory) {
        return ps().slotPricesUSD;
    }

    function updateSlotPriceUSD(uint256 slotId, uint256 newUSDPrice) external onlyPriceFeedAdmin {
        require(slotId >= 1 && slotId <= 12, "Invalid slot");
        require(newUSDPrice > 0, "Price must be positive");

        PriceFeedStorage storage ds = ps();
        ds.slotPricesUSD[slotId - 1] = newUSDPrice;

        uint256 corePrice = getSlotPriceInCore(slotId);
        emit SlotPriceUpdated(slotId, corePrice, newUSDPrice);
    }

    // Config
    function setDynamicPricingEnabled(bool enabled) external onlyPriceFeedAdmin {
        ps().dynamicPricingEnabled = enabled;
        emit DynamicPricingToggled(enabled);
    }

    function setPriceUpdateInterval(uint256 interval) external onlyPriceFeedAdmin {
        require(interval >= 60, "Too short");
        ps().priceUpdateInterval = interval;
    }

    function setPriceFeedAdmin(address newAdmin) external onlyPriceFeedAdmin {
        require(newAdmin != address(0), "Invalid admin");
        ps().priceFeedAdmin = newAdmin;
    }

    function setManualCorePrice(uint256 manualPrice) external onlyPriceFeedAdmin {
        require(manualPrice > 0, "Invalid price");
        PriceFeedStorage storage ds = ps();
        ds.cachedCorePrice = manualPrice;
        ds.lastPriceUpdate = block.timestamp;
        emit PriceUpdated(manualPrice, block.timestamp);
    }

    function getPriceFeedConfig()
        external
        view
        returns (
            address feed,
            uint256 interval,
            uint256 lastUpdate,
            uint256 cachedPrice,
            bool enabled,
            address admin
        )
    {
        PriceFeedStorage storage ds = ps();
        return (
            address(ds.corePriceFeed),
            ds.priceUpdateInterval,
            ds.lastPriceUpdate,
            ds.cachedCorePrice,
            ds.dynamicPricingEnabled,
            ds.priceFeedAdmin
        );
    }

    function needsPriceUpdate() external view returns (bool) {
        return (block.timestamp - ps().lastPriceUpdate) >= ps().priceUpdateInterval;
    }
}
