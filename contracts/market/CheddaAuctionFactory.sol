//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "./CheddaAuction.sol";

contract AuctionFactory {
    CheddaAuction[] public auctions;

    event AuctionCreated(address indexed auctionContract, address indexed owner, uint numAuctions);

    function createAuction(uint256 bidIncrement, uint256 startBlock, uint256 endBlock) public {
        CheddaAuction newAuction = new CheddaAuction(startBlock, endBlock, bidIncrement);
        auctions.push(newAuction);

        emit AuctionCreated(address(newAuction), msg.sender, auctions.length);
    }

    function allAuctions() public view returns (CheddaAuction[] memory) {
        return auctions;
    }
}
