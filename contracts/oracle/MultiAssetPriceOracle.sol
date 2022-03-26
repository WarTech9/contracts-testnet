//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import { IPriceFeed } from "./IPriceFeed.sol";

contract MultiAssetPriceOracle is Ownable, IPriceFeed {

    // token address to price feed address 
    mapping(address => IPriceFeed) public priceFeeds;

    function setOracle(address token, address priceFeed) public onlyOwner {
        require(token != address(0) && priceFeed != address(0), "ERR: Zero address");
        priceFeeds[token] = IPriceFeed(priceFeed);
    }

    // TODO: use Chainlink price consumer
    /// @dev Explain to a developer any extra details
    /// @return Returns the latest price
    function readPrice(address token, uint256 tokenID) public override view returns (int) {
        IPriceFeed priceFeed = priceFeeds[token];
        require(address(priceFeed) != address(0), "No price feed");
        int price = priceFeed.readPrice(token, tokenID);(token, tokenID);
        return price;
    }
}
