//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface NFTListingPolicy {
    function canList(address _tokenAddress) external returns (bool);
}

contract MarketNFTListingPolicy is Ownable, NFTListingPolicy {

    mapping(address => bool) public allowed;

    function allow(address _tokenAddress) external onlyOwner() {
        require(!allowed[_tokenAddress], "token already approved");
        allowed[_tokenAddress] = true;
    }

    function disallow(address _tokenAddress) external onlyOwner() {
        require(allowed[_tokenAddress], "token not allowed");
        delete allowed[_tokenAddress];
    }

    function canList(address _tokenAddress) external override view returns (bool) {
        return allowed[_tokenAddress];
    }
}