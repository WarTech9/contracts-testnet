//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Chedda {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  mapping (address => uint256) public balances;

  event Minted(uint256 amount, address to);
  event Burned(uint256 amount, address from);

  modifier changer() {
    _;
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