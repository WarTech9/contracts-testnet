//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

interface IYieldStrategy {
    function initialInvestment() external returns (uint256 amountInvested);
    function shareToken() external returns (address);
    function shares() external returns (uint256 shares);
    function rebalance() external;
    function invest() external;
    function harvest() external;
}