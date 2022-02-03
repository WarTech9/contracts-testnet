//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

    uint256 private _totalSupply = 1_000_000 ether;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, _totalSupply);
    }
}