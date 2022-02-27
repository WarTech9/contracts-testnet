//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {

    uint256 private _totalSupply = 100_000_000 ether;

    constructor() ERC20("USDC.c", "USDC.c") {
        _mint(msg.sender, _totalSupply);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}