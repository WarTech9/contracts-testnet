//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEntropy {
    function addEntropy() external;
    function randomNumber(uint256 max) external view returns (uint256);
}

contract CheddaEntropy is IEntropy {
    bytes32 private currentEntropy;

    function addEntropy() public override {
        bytes32 currentEventHash = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        currentEntropy = keccak256(abi.encodePacked(currentEventHash, currentEntropy));
    }

    function randomNumber(uint256 max) public override view returns (uint256) {
        return uint(currentEntropy) % max;
    }

    function getEntroy() private view returns (bytes32) {
        return currentEntropy;
    }
}