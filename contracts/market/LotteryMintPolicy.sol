//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MintLottery.sol";
import "./IMintPolicy.sol";

contract LotteryMintPolicy is IMintPolicy {
  MintLottery private lot;

  constructor(MintLottery lottery) {
    lot = lottery;
  }

  function canMint() external override pure returns (bool) {
    return true;
  }

  function redeem() external override pure returns (bool) {
    return true;
  }
}