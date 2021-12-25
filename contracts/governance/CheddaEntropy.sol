//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CheddaEntropy {
    bytes32 private currentEntropy;

    function addEntropy() public {
        bytes32 currentEventHash = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        currentEntropy = keccak256(abi.encodePacked(currentEventHash, currentEntropy));
    }

    function getEntroy() public view returns (bytes32) {
        return currentEntropy;
    }

    function randomNumber(uint256 max) public view returns (uint256) {
        return uint(currentEntropy) % max;
    }
}