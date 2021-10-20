//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMintPolicy.sol";

contract OpenMintPolicy is IMintPolicy {

  function canMint() external override pure returns (bool) {
    return true;
  }

  function redeem() external override pure returns (bool) {
    return true;
  }
}