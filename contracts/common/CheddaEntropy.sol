//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

interface IEntropy {
    function addEntropy() external;
    function randomNumber(uint256 max) external view returns (uint256);
}

contract CheddaEntropy is IEntropy {
    bytes32 private currentEntropy;

    mapping (bytes32 => uint256[]) public tokenIds;

    function addEntropy() external override {
        bytes32 currentEventHash = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        currentEntropy = keccak256(abi.encodePacked(currentEventHash, currentEntropy));
    }

    function randomNumber(uint256 max) external override view returns (uint256) {
        return uint(currentEntropy) % max;
    }

    function getEntroy() private view returns (bytes32) {
        return currentEntropy;
    }

    function idsWithProperty(string memory property) public view returns(uint256[] memory) {
        bytes32 packed = keccak256(abi.encode(property));
        return tokenIds[packed];
    }
}
