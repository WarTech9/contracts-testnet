//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/CheddaAddressRegistry.sol";
import "./NFTWhitelistDrop.sol";

contract DropManager is Ownable {
    ICheddaDrop[] public drops;

    function createDrop(
        uint256 start,
        uint256 end,
        address contractAddress,
        string memory metadataURI
    ) public onlyOwner {
        ICheddaDrop drop = new NFTWhitelistDrop(
            start,
            end,
            contractAddress,
            metadataURI
        );
        drops.push(drop);
    }

    function getDrops() public view returns (ICheddaDrop[] memory) {
        return drops;
    }
}
