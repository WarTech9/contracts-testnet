// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IPriceFeed } from "./IPriceFeed.sol";

contract ChainlinkPriceConsumerV3 is IPriceFeed {

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

    function readPrice(address token, uint256 tokenID) public override view returns (int) {
        // silence
        token;
        tokenID;
        return getLatestPrice();
    }
}