//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ICheddaAddressRegistry {
    function chedda() external view returns (address);

    function cheddaXP() external view returns (address);

    function cheddaNFT() external view returns (address);

    function dappStore() external view returns (address);

    function market() external view returns (address);

    function dappStoreExplorer() external view returns (address);
    
    function marketExplorer() external view returns (address);

    function rewards() external view returns (address);

    function entropy() external view returns (address);

    function drops() external view returns (address);

    function loanManager() external view returns (address);

    function wrappedNativeToken() external view returns (address);

    function priceConsumer() external view returns (address);

    function nftFactory() external view returns (address);
}

interface IRegisteredContract {
    function registryAddress() external view returns (address);
    function updateRegistry(address registryAddress) external;
}

contract CheddaAddressRegistry is Ownable {

    event CheddaUpdated(address indexed newAddress, address indexed caller);
    event CheddaXPUpdated(address indexed newAddress, address indexed caller);
    event DappStoreUpdated(address indexed newAddress, address indexed caller);
    event DappExplorerUpdated(address indexed newAddress, address indexed caller);
    event MarketUpdated(address indexed newAddress, address indexed caller);
    event MarketExplorerUpdated(address indexed newAddress, address indexed caller);
    event RewardsUpdated(address indexed newAddress, address indexed caller);
    event EntropyUpdated(address indexed newAddress, address indexed caller);
    event MintPolicyUpdated(address indexed newAddress, address indexed caller);
    event GovernorUpdated(address indexed newAddress, address indexed caller);
    event CheddaNFTUpdated(address indexed newAddress, address indexed caller);
    event DropsUpdated(address indexed newAddress, address indexed caller);
    event LoanManagerUpdated(address indexed newAddress, address indexed caller);
    event WrappedNativeTokenUpdated(address indexed tokenAddress, address indexed caller);
    event PriceConsumerUpdated(address indexed consumerAddress, address indexed caller);
    event NFTFactoryUpdated(address indexed factoryAddress, address indexed caller);

    address public chedda;
    address public cheddaXP;
    address public cheddaNFT;
    address public dappStore;
    address public market;
    address public dappStoreExplorer;
    address public marketExplorer;
    address public governor;
    address public mintPolicy;
    address public entropy;
    address public rewards;
    address public drops;
    address public loanManager;
    address public priceConsumer;
    address public nftFactory;
    address public wrappedNativeToken;

    function setChedda(address _chedda) external onlyOwner() {
        chedda = _chedda;
        emit CheddaUpdated(cheddaXP, _msgSender());
    }

    function setCheddaXP(address xp) external onlyOwner() {
        cheddaXP = xp;
        emit CheddaXPUpdated(cheddaXP, _msgSender());
    }

    function setCheddaNFT(address nftAddress) external onlyOwner() {
        cheddaNFT = nftAddress;
        emit CheddaNFTUpdated(cheddaNFT, _msgSender());
    }

    function setDappStore(address storeAddress) external onlyOwner() {
        dappStore = storeAddress;
        emit DappStoreUpdated(dappStore, _msgSender());
    }

    function setDappstoreExplorer(address dappStoreExplorerAddress) external onlyOwner() {
        dappStoreExplorer = dappStoreExplorerAddress;
        emit DappExplorerUpdated(dappStoreExplorer, _msgSender());
    }

    function setMarket(address marketAddress) external onlyOwner() {
        market = marketAddress;
        emit MarketUpdated(market, _msgSender());
    }

    function setMarketExplorer(address marketExplorerAddress) external onlyOwner() {
        marketExplorer = marketExplorerAddress;
        emit MarketExplorerUpdated(marketExplorer, _msgSender());
    }

    function setGovernor(address governorAddress) external onlyOwner() {
        governor = governorAddress;
        emit GovernorUpdated(governor, _msgSender());
    }

    function setMintPolicy(address mintPolicyAddress) external onlyOwner() {
        mintPolicy = mintPolicyAddress;
        emit MintPolicyUpdated(mintPolicyAddress, _msgSender());
    }

    function setEntropy(address entropyAddress) external onlyOwner() {
        entropy = entropyAddress;
        emit EntropyUpdated(entropyAddress, _msgSender());
    }

    function setRewards(address rewardsAddress) external onlyOwner() {
        rewards = rewardsAddress;
        emit RewardsUpdated(rewardsAddress, _msgSender());
    }

    function setDrops(address dropsAddress) external onlyOwner() {
        drops = dropsAddress;
        emit DropsUpdated(dropsAddress, _msgSender());
    }

    function setLoanManager(address loanManagerAddress) external onlyOwner() {
        loanManager = loanManagerAddress;
        emit LoanManagerUpdated(loanManagerAddress, _msgSender());
    }

    function setWrappedNativeToken(address tokenAddress) external onlyOwner() {
        wrappedNativeToken = tokenAddress;
        emit WrappedNativeTokenUpdated(tokenAddress, _msgSender());
    }

    function setPriceConsumer(address consumerAddress) external onlyOwner() {
        priceConsumer = consumerAddress;
        emit PriceConsumerUpdated(consumerAddress, _msgSender());
    }

    function setNFTFactory(address factoryAddress) external onlyOwner() {
        nftFactory = factoryAddress;
        emit NFTFactoryUpdated(factoryAddress, _msgSender());
    }
}
