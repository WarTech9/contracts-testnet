//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CheddaRewardsDistributor {

    event RewardsSent(address indexed toVault, uint32 weight, uint256 amount);

    struct RewardsTarget {
        address vaultAddress;
        uint32 weight;
    }

    RewardsTarget[] public targets;
    IERC20 public _token;

    modifier onlyContract() {
        _;
    }

    function distribute() internal {
        uint256 balance = _token.balanceOf(address(this));
        if (balance == 0) {
            return;
        }
        uint32 totalWeights = 0;
        for (uint256 i = 0; i < targets.length; i++) {
            totalWeights += targets[i].weight;
        }

        for (uint256 i = 0; i < targets.length; i++) {
            uint256 amount = balance * targets[i].weight / totalWeights;
            _token.transfer(targets[i].vaultAddress, amount);
            emit RewardsSent(targets[i].vaultAddress, targets[i].weight, amount);
        }
    }
}