//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

library ConcatHelper {
    function concat(bytes memory a, bytes memory b) internal pure returns (bytes memory) {
        return abi.encodePacked(a, b);
    }
}