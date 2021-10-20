//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/IterableMapping.sol";

// market analytics
contract CheddaMarketExplorer {

  struct Trade {
    address nftContract;
    uint256 tokenId;
    uint256 price;
  }
  using IterableMapping for IterableMapping.Map;
  IterableMapping.Map private allListings;

  // Day start timestamp => daily volume
  mapping(uint256 => uint256) public dailyVolume;
  mapping(uint256 => Trade[]) public trades;
    mapping(address => uint256) public likes;
    mapping(address => uint256) public dislikes;
    
  function collections() public {

  }
}