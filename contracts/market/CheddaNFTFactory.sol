//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/CheddaAddressRegistry.sol";
import "./MarketNFT.sol";

contract CheddaNFTFactory is Ownable {
    address public registry;

    function updateRegistry(address registryAddress) public onlyOwner() {
        registry = registryAddress;
    }

    function createNFT(
        uint256 _mintFee,
        address payable _feeReceipient,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public returns (address) {
        MarketNFT nft = new MarketNFT(
            _mintFee,
            _feeReceipient,
            _name,
            _symbol,
            _uri
        );
        return address(nft);
    }
}
