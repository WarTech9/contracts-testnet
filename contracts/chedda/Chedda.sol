//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/CheddaAddressRegistry.sol";

contract Chedda is Context, Ownable {
    event Minted(uint256 amount, address to);
    event Burned(uint256 amount, address from);

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

    function mint(uint256 _amount, address _owner) public onlyRewards() {
        _mint(_amount, _owner);
    }

    function _mint(uint256 _amount, address _owner) internal {
        require(_amount != 0, "amount should not be 0");
        balances[_owner] = balances[_owner] + _amount;
        emit Minted(_amount, _owner);
    }

    function _burn(uint256 _amount) internal {
        require(_amount > 0, "amount must be > 0");
        require(balanceOf(msg.sender) >= _amount, "Balance < amount");
        balances[msg.sender] -= _amount;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}
