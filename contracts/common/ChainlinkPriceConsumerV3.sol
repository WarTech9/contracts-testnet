// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkPriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /// @dev Creates the price consumer 
    /// @param feedAddress  The address of the price feed.
    constructor(address feedAddress) {
        priceFeed = AggregatorV3Interface(feedAddress);
    }

    /// @dev Explain to a developer any extra details
    /// @return Returns the latest price
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}