// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "@api3/services/contracts/IRrpBeaconServer.sol";

contract API3BeaconReader {
    IRrpBeaconServer public immutable rrpBeaconServer;

    constructor(address rrpBeaconServerAddress) {
        require(rrpBeaconServerAddress != address(0), "Zero address");
        rrpBeaconServer = IRrpBeaconServer(rrpBeaconServerAddress);
    }

    function readBeacon(bytes32 beaconId)
        external
        view
        returns (int224 value, uint256 timestamp)
    {
        (value, timestamp) = rrpBeaconServer.readBeacon(beaconId);
    }
}