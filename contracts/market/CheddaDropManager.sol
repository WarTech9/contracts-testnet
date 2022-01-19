//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../common/CheddaAddressRegistry.sol";
import "./NFTWhitelistDrop.sol";

contract CheddaDropManager is Ownable {

    /// @notice Emitted when a new drop is created
    /// @param start the start time of the drop
    /// @param end the end time of the drop
    /// @param contractAddress the address for the drop created
    /// @param tokenAddress This can be an NFT of ERC20 address
    /// @param metadataURI the uri for drop metadata
    event DropCreated(
        uint256 indexed id,
        uint256 indexed start, 
        uint256 indexed end, 
        address contractAddress,
        address tokenAddress,
        string metadataURI
    );

    /// @notice Details of a drop
    /// @return Documents the return variables of a contract’s function state variable
    /// @param id unique drop id
    /// @param start start time for this drop
    /// @param end end time for this drop
    /// @param metadataURI URI containing drop info like name, images, details
    /// @param contractAddress address for this drop
    /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)
    struct DropDetails {
        uint256 id;
        uint256 start;
        uint256 end;
        address contractAddress;
        string metadataURI;
    }

    using Counters for Counters.Counter;
    Counters.Counter internal counter;

    DropDetails[] public drops;

    address public registry;

    function updateRegistry(address registryAddress) public onlyOwner() {
        registry = registryAddress;
    }

    function createDrop(
        uint256 start,
        uint256 end,
        address tokenAddress,
        string memory metadataURI
    ) public
     onlyOwner 
     returns (address) {
        counter.increment();
        NFTWhitelistDrop drop = new NFTWhitelistDrop(
            start,
            end,
            tokenAddress,
            metadataURI
        );
        drop.updateRegistry(registry);
        address dropAddress = address(drop);
        uint256 id = counter.current();
        drops.push(DropDetails({
            id: id,
            start: start,
            end: end,
            contractAddress: dropAddress,
            metadataURI: metadataURI
        }));
        emit DropCreated(id, start, end, dropAddress, tokenAddress, metadataURI);
        return dropAddress;
    }

    function getDrops() public view returns (DropDetails[] memory) {
        return drops;
    }

    function getDrop(uint256 id) public view returns (DropDetails memory) {
        for (uint256 i = 0; i < drops.length; i++) {
            DropDetails memory drop = drops[i];
            if (drop.id == id) {
                return drop;
            }
        }
        revert("Drop: Invalid id");
    }

}
