//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

interface ICheddaVerifier {
    function requestVerification(address user, bytes memory token) external returns(bytes32);
    function fulfill(bytes32 requestId, bool result) external;
}
