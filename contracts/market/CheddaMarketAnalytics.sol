//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

contract CheddaMarketAnalytics {
    mapping (uint8 => mapping (uint8 => mapping (uint8 => uint256))) public dailyVolume;
}