//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MintLottery {
    address public manager;
  address payable[] public players;
  mapping (address => bool) public winners;
  mapping (address => bool) public redeemed;

  constructor() {
    manager = msg.sender;
  }

  function enter() public payable {
    require(msg.value > .01 ether, "Your balance can not be 0");

    players.push(payable(msg.sender));
  }

  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
  }

  function pickWinner() public restricted {
    uint index = random() % players.length;

    address payable winner = players[index];
    players = new address payable[](0);
    winner.transfer(address(this).balance);
  }

  function getPlayers() public view returns (address payable[] memory) {
    return players;
  }

  function claimPrize() public {
    require(winners[msg.sender] == true, "Not a winner");
    require(redeemed[msg.sender] == false, "Prize already claimed");

    redeemed[msg.sender] = true;
  }

  modifier restricted() {
    require(msg.sender == manager);
    _;
  }
}