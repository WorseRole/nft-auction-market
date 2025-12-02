// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 使用本地路径，不是 @chainlink 路径
import "./interfaces/AggregatorV3Interface.sol";

library  PriceConverter {
    // Chainlink 价格 (8位小数): 200000000000 Chainlink 价格预言机返回的价格通常是 8位小数：
    // 在以太坊中，代币通常使用 18位小数：
    // 所以是 乘以 1e10
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1e10);
    }

    function getConversionRate(uint256 amount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 price = getPrice(priceFeed);
        return (amount * price) / 1e18;
    }
}
