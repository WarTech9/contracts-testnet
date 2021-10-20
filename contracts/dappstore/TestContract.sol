//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TestContract {
  mapping(address => uint256) private balances;
  mapping(address => mapping(address => uint256)) public approvals;

  function foo() public {
    balances[msg.sender] = 100;
  }

  function invest() public payable {
    require(msg.value > 0, "Value is 0");
    balances[msg.sender] += msg.value;
  }

  function approve(address spender, uint256 amount) public {
    require(msg.sender != spender, "Can not approve yourself");
    approvals[msg.sender][spender] = amount;
  }

  function removeApproval(address spender) public {
    delete approvals[msg.sender][spender];
  }

}