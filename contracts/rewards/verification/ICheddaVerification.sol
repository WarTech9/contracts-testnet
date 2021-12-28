//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICheddaVerification {
    function verify(bytes memory input1, bytes memory input2) external;
}
