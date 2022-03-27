// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "@api3/services/contracts/IRrpBeaconServer.sol";
import { IPriceFeed } from "./IPriceFeed.sol";

contract API3BeaconReader is IPriceFeed {
    IRrpBeaconServer public immutable rrpBeaconServer;
    bytes32 public immutable beacon;

    constructor(address rrpBeaconServerAddress, bytes32 _beacon) {
        require(rrpBeaconServerAddress != address(0), "Zero address");
        rrpBeaconServer = IRrpBeaconServer(rrpBeaconServerAddress);
        beacon = _beacon;
    }

    function readBeacon(bytes32 beaconId)
        public
        view
        returns (int224 value, uint256 timestamp) {
        (value, timestamp) = rrpBeaconServer.readBeacon(beaconId);
    }

    function readPrice(address token, uint256 tokenID) external override view returns (int value) {
        // silence
        token;
        tokenID;
        (int224 _value, uint _timestamp) = readBeacon(beacon);
        value = int256(_value);
    }
}
