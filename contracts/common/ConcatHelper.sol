//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ConcatHelper {
    function concat(bytes memory a, bytes memory b) internal pure returns (bytes memory) {
        return abi.encodePacked(a, b);
    }
}