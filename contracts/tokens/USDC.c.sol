//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {

    constructor(address account, uint256 _totalSupply) ERC20("USDC Chedda Testnet", "USDC.c") {
        _mint(account, _totalSupply);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}