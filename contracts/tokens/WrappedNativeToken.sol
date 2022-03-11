//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Wrapped Native Token
/// @notice This is a placeholder for wrapped native asset (WETH, WMATIC, WFTM etc.)
/// @dev Not a real wrapped asset. Does not support converting to or from native asset.
/// Only used in testnet for testing.
contract WrappedNativeToken is ERC20 {

    constructor(string memory name, string memory symbol, address account, uint256 _totalSupply) 
    ERC20(name, symbol) {
        _mint(account, _totalSupply);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}