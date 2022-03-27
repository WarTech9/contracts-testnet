//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

interface IInterestRateModel {
    function borrowAPR() external view returns (uint128);
    function depositAPR() external view returns (uint128);
}

// placeholder interest rate policy.
// dynamic policy to be implemented based on demand/supply
contract FixedInterestRateModel is IInterestRateModel {
    function borrowAPR() external pure returns (uint128) {
      return 775 * 100_000 / 100; // TODO: make dynamic based on supply/demand. 7.75%
    }

    function depositAPR() external pure returns (uint128) {
      return  350 * 100_000 / 100; // 3.5%
    }
}
