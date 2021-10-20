//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMintPolicy {
  function canMint() external returns (bool);
  function redeem() external returns (bool);
}