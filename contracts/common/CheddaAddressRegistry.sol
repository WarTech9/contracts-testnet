//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CheddaAddressRegistry is Ownable {

    event CheddaXPUpdated(address indexed newAddress, address indexed caller);
    event DappStoreUpdated(address indexed newAddress, address indexed caller);
    event DappExplorerUpdated(address indexed newAddress, address indexed caller);
    event MarketUpdated(address indexed newAddress, address indexed caller);
    event MarketExplorerUpdated(address indexed newAddress, address indexed caller);
    event RewardsUpdated(address indexed newAddress, address indexed caller);
    event EntroypUpdated(address indexed newAddress, address indexed caller);
    event MintPolicyUpdated(address indexed newAddress, address indexed caller);
    event GovernorUpdated(address indexed newAddress, address indexed caller);

    address public cheddaXP;
    address public dappStore;
    address public market;
    address public dappStoreExplorer;
    address public marketExplorer;
    address public govenor;
    address public mintPolicy;
    address public entropy;
    address public rewards;

    function setCheddaXP(address xp) external onlyOwner() {
        cheddaXP = xp;
        emit CheddaXPUpdated(xp, _msgSender());
    }

    function setRewards(address rewardsAddress) external onlyOwner() {
        rewards = rewardsAddress;
        emit RewardsUpdated(rewardsAddress, _msgSender());
    }

    function setDappStore(address storeAddress) external onlyOwner() {
        dappStore = storeAddress;
        emit DappStoreUpdated(storeAddress, _msgSender());
    }

    function setDappstoreExplorer(address dappStoreExplorerAddress) external onlyOwner() {
        dappStoreExplorer = dappStoreExplorerAddress;
        emit DappExplorerUpdated(dappStoreExplorerAddress, _msgSender());
    }

    function setMarket(address marketAddress) external onlyOwner() {
        market = marketAddress;
        emit MarketUpdated(marketAddress, _msgSender());
    }

    function setMarketExplorer(address marketExplorerAddress) external onlyOwner() {
        marketExplorer = marketExplorerAddress;
        emit MarketExplorerUpdated(marketExplorerAddress, _msgSender());
    }

    function setGovenor(address govenorAddress) external onlyOwner() {
        govenor = govenorAddress;
        emit GovernorUpdated(govenorAddress, _msgSender());
    }

    function setMintPolicy(address mintPolicyAddress) external onlyOwner() {
        mintPolicy = mintPolicyAddress;
        emit MintPolicyUpdated(mintPolicyAddress, _msgSender());
    }

    function setEntropy(address entropyAddress) external onlyOwner() {
        entropy = entropyAddress;
        emit EntroypUpdated(entropyAddress, _msgSender());
    }
}