//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CheddaNFT.sol";

contract CheddaWhitelistedNFT is CheddaNFT {
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public claimed;

    constructor(
        uint256 _mintFee,
        address payable _feeReceipient,
        address[] memory whitelist,
        string memory name,
        string memory symbol,
        string memory metadataURI
    ) CheddaNFT(_mintFee, _feeReceipient, name, symbol, metadataURI) {
        _createWhitelist(whitelist);
    }

    function _createWhitelist(address[] memory whitelist) private onlyOwner {
        for (uint256 i = 0; i < whitelist.length; i++) {
            whitelisted[whitelist[i]] = true;
        }
    }
}
