// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

interface IPriceFeed {
    /// @notice Get latest price of asset. For ERC-20 tokens, `tokenID` parameter is unused.
    /// tokenID parameter is for forwards compatibility.
    /// @param token address of the asset's token.
    /// @param tokenID ID of specific token, for instance with ERC-721. Unused for ERC-20 
    /// tokens.
    /// @return price the price of the asset
    function readPrice(address token, uint256 tokenID) external view returns (int price);
}
