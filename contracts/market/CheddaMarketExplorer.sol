//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "../library/IterableMapping.sol";
import "./CheddaMarket.sol";
import "./CheddaNFT.sol";
import "hardhat/console.sol";

// market explorer
contract CheddaMarketExplorer {
    struct Trade {
        address nftContract;
        uint256 tokenId;
        uint256 price;
    }

    struct Collection {
        address nftContract;
        string metadataURI;
        bool exists;
    }

    struct CollectionStats {
        address nftContract;
        uint16 itemCount;
        uint16 ownerCount;
        uint256 floorPrice;
        uint256 volumeTraded;
    }

    struct MarketItem {
        address nftContract;
        uint256 tokenID;
        string tokenURI;
        uint256 price;
        uint256 listingTime;
    }

    struct NFTDetails {
        address nftContract;
        uint256 tokenID;
        string tokenURI;
    }

    // Day start timestamp => daily volume
    mapping(uint256 => uint256) public dailyVolume;
    mapping(uint256 => Trade[]) public trades;
    mapping(address => uint256) public likes;
    mapping(address => uint256) public dislikes;

    // user address => (nft contract address => tokenId)
    mapping(address => mapping(address => uint256)[]) public itemsOwnedMap;

    struct NFTPair {
        address nftContract;
        uint256 tokenID;
    }
    mapping(address => NFTPair[]) public itemsOwned;
    mapping(address => NFTPair[]) public itemsCreated;

    MarketItem[] public allItems;

    bytes4 private constant INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant INTERFACE_ID_ICHEDDA_NFT = 0x03ee438c;

    mapping(address => Collection) public collections;
    address[] public collectionList;
    // NFT address to market item
    mapping(address => MarketItem[]) public collectionItems;

    function getCollections() public view returns (Collection[] memory) {
        Collection[] memory returnList = new Collection[](
            collectionList.length
        );
        for (uint256 i = 0; i < collectionList.length; i++) {
            address nftAddress = collectionList[i];
            Collection memory c = collections[nftAddress];
            returnList[i] = c;
        }
        return returnList;
    }

    function itemsInCollection(address nftContract)
        public
        view
        returns (MarketItem[] memory)
    {
        return collectionItems[nftContract];
    }

    function getCollectionDetails(address nftContract)
        public
        view
        returns (Collection memory)
    {
        return collections[nftContract];
    }

    function getAllItems() public view returns (MarketItem[] memory) {
        return allItems;
    }

    function newlyListed(uint256 time)
        public
        view
        returns (MarketItem[] memory)
    {}

    function popularItems() public view {}

    function getNFTDetails(address nftContract, uint256 tokenID)
        public
        view
        returns (NFTDetails memory)
    {
        if (_isERC721Metadata(nftContract)) {
            IERC721Metadata tokenWithMetadata = IERC721Metadata(nftContract);
            string memory tokenURI = tokenWithMetadata.tokenURI(tokenID);
            return NFTDetails(nftContract, tokenID, tokenURI);
        } else {
            revert("Invalid token ID");
        }
    }

    function getMarketItem(address nftContract, uint256 tokenID)
        public
        view
        returns (MarketItem memory)
    {
        require(collectionItems[nftContract].length > 0, "Item not found");
        for (uint256 i = 0; i < collectionItems[nftContract].length; i++) {
            if (collectionItems[nftContract][i].tokenID == tokenID) {
                return collectionItems[nftContract][i];
            }
        }
        revert("Item not found");
    }

    // todo: add marketOnly modifier
    function reportListing(
        address nftContract,
        uint256 tokenID,
        uint256 price,
        address seller
    ) public {
        string memory tokenURI = "";
        if (_isERC721Metadata(nftContract)) {
            IERC721Metadata tokenWithMetadata = IERC721Metadata(nftContract);
            tokenURI = tokenWithMetadata.tokenURI(tokenID);
        }
        MarketItem memory item = MarketItem(
            nftContract,
            tokenID,
            tokenURI,
            price,
            block.timestamp
        );
        allItems.push(item);
        if (!collections[nftContract].exists) {
            string memory metadatURI = "";
            // todo: fix the _isCheddaNFT check
            // if (_isCheddaNFT(nftContract)) {
            ICheddaNFT nftMetadata = ICheddaNFT(nftContract);
            metadatURI = nftMetadata.metadataURI();
            // }
            collections[nftContract] = Collection(
                nftContract,
                metadatURI,
                true
            );
            collectionList.push(nftContract);
        }

        collectionItems[nftContract].push(item);
        itemsOwned[seller].push(NFTPair(nftContract, tokenID));
    }

    // todo: add marketOnly modiifer
    function reportMarketSale(
        address nftContract,
        uint256 tokenID,
        address seller,
        address buyer
    ) public {
        uint256 index = 0;
        for (uint256 i = 0; i < allItems.length; i++) {
            if (
                allItems[i].nftContract == nftContract &&
                allItems[i].tokenID == tokenID
            ) {
                index = i;
            }
        }
        if (index != 0) {
            allItems[index] = allItems[allItems.length - 1];
            allItems.pop();
        }

        // // update itemsOwned
        uint256 sellerItemsOwned = itemsOwned[seller].length;
        for (uint256 i = 0; i < sellerItemsOwned; i++) {
            NFTPair memory item = itemsOwned[seller][i];
            if (item.nftContract == nftContract && item.tokenID == tokenID) {
                itemsOwned[seller][i] = itemsOwned[seller][sellerItemsOwned - 1];
                itemsOwned[seller].pop();
                break;
            }
        }

        itemsOwned[buyer].push(NFTPair(nftContract, tokenID));
    }

    function getItemsOwned(address user)
        public
        view
        returns (NFTDetails[] memory)
    {
        uint256 arraySize = itemsOwned[user].length;
        NFTDetails[] memory usersItems = new NFTDetails[](arraySize);
        for (uint256 i = 0; i < arraySize; i++) {
            NFTPair storage currentItem = itemsOwned[user][i];
            string memory tokenURI = IERC721Metadata(currentItem.nftContract)
                .tokenURI(currentItem.tokenID);
            usersItems[i] = NFTDetails(
                currentItem.nftContract,
                currentItem.tokenID,
                tokenURI
            );
        }
        return usersItems;
    }

    function _isERC721Metadata(address nftContract)
        internal
        view
        returns (bool)
    {
        return (
            IERC165(nftContract).supportsInterface(INTERFACE_ID_ERC721_METADATA)
        );
    }

    function _isCheddaNFT(address nftContract) internal view returns (bool) {
        return (
            ICheddaNFT(nftContract).supportsInterface(INTERFACE_ID_ICHEDDA_NFT)
        );
    }
}
