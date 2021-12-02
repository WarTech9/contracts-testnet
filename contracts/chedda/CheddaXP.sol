//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/CheddaAddressRegistry.sol";

contract CheddaXP is Context, Ownable {
    event Minted(uint256 amount, address to);
    event Burned(uint256 amount, address from);
    event Slashed(uint256 amount, address owner);

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    CheddaAddressRegistry public registry;
    mapping(address => uint256) public balances;

    modifier onlyRewards() {
        require(_msgSender() == registry.rewards(), "Not allowed: Only Rewards");
        _;
    }

    function updateRegistry(address registryAddress) external onlyOwner() {
        registry = CheddaAddressRegistry(registryAddress);
    }

    function mint(uint256 amount, address owner) public onlyRewards() {
        _mint(amount, owner);
    }

    function slash(uint256 amount, address owner) public onlyRewards() {
        uint256 balance = balanceOf(owner);
        uint256 amountToBurn = amount;
        if (amountToBurn > balance) {
            amountToBurn = balance;
        }
        require(balance - amountToBurn >= 0, "Balance: Invalid amount");
        require(totalSupply - amountToBurn >= 0, "Total Supply: Invalid amount");
        totalSupply -= amountToBurn;
        balances[owner] -= amountToBurn;
        emit Slashed(amount, owner);
    }

    function burn(uint256 amount) public {
        _burn(amount);
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function _mint(uint256 amount, address owner) internal {
        require(amount != 0, "amount should not be 0");
        totalSupply += amount;
        balances[owner] = balances[owner] + amount;
        emit Minted(amount, owner);
    }

    function _burn(uint256 amount) internal {
        require(amount > 0, "amount must be > 0");
        require(balanceOf(msg.sender) >= amount, "Balance < amount");
        totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Burned(amount, _msgSender());
    }

}
