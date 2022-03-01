//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC4626 } from "./ERC4626.sol";
import { ERC20 } from "./ERC20.sol";
import { Chedda } from "./Chedda.sol";

/// @title Staked Chedda
/// @notice Tokenized vault representing staked CHEDDA rewards.
/// @dev Must be set as CHEDDA token vault for new token emission.
contract sChedda is ERC4626 {

    Chedda public chedda;

    constructor(address _chedda) 
    ERC4626(ERC20(_chedda), "Staked Chedda", "sChedda") {
        chedda = Chedda(_chedda);
    }

    /// @notice Total amount of Chedda staked.
    /// @return Amount of Chedda staked
    function totalAssets() public override view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /// @notice Stake Chedda.
    /// @param amount Amount to stake.
    /// @dev mints sChedda
    /// @return shares Amount of sChedda minted.
    function stake(uint256 amount) public returns (uint256 shares) {
        shares = deposit(amount, msg.sender);
        chedda.rebase();
    }

    /// @notice Stake Chedda.
    /// @param amount Amount to stake.
    /// @dev burns sChedda
    /// @return shares Amount of sChedda burned.
    function unstake(uint256 amount) public returns (uint256 shares) {
        chedda.rebase();
        shares = withdraw(amount, msg.sender, msg.sender);
    }
}