//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTMintRegistry {

  modifier canMint(address tokenAddress, uint256 itemId) {
    _;
  }
}