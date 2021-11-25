//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CheddaAddressRegistry is Ownable {

    address public dappStore;
    address public market;
    address public dappStoreExplorer;
    address public marketExplorer;
    address public govenor;
    address public mintPolicy;
    address public entropy;
    address public rewards;

    function setDappStore(address storeAddress) external onlyOwner() {
        dappStore = storeAddress;
    }

    function setMarket(address marketAddress) external onlyOwner() {
        market = marketAddress;
    }

    function setDappstoreExplorer(address dappStoreExplorerAddress) external onlyOwner() {
        dappStoreExplorer = dappStoreExplorerAddress;
    }

    function setMarketExplorer(address marketExplorerAddress) external onlyOwner() {
        marketExplorer = marketExplorerAddress;
    }

    function setGovenor(address govenorAddress) external onlyOwner() {
        govenor = govenorAddress;
    }

    function setMintPolicy(address mintPolicyAddress) external onlyOwner() {
        mintPolicy = mintPolicyAddress;
    }

    function setEntropy(address entropyAddress) external onlyOwner() {
        entropy = entropyAddress;
    }

    function setRewards(address rewardsAddress) external onlyOwner() {
        rewards = rewardsAddress;
    }
}