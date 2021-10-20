//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CheddaAddressRegistry is Ownable {

    address public dappstore;
    address public market;
    address public govenor;
    address public mintPolicy;
    address public entropy;

    function setDappstore(address _storeAddress) public onlyOwner() {
        dappstore = _storeAddress;
    }

    function setMarket(address _marketAddress) external onlyOwner() {
        market = _marketAddress;
    }

    function setGovenor(address _govenorAddress) external onlyOwner() {
        govenor = _govenorAddress;
    }

    function setMintPolicy(address _mintPolicy) external onlyOwner() {
        mintPolicy = _mintPolicy;
    }

    function setEntropy(address _entropy) external onlyOwner() {
        entropy = _entropy;
    }
}