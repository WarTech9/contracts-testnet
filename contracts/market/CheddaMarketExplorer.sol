//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CheddaMarket.sol";
import "../chedda/CheddaRewards.sol";
import "./CheddaNFT.sol";
import "../common/CheddaAddressRegistry.sol";

// market explorer
contract CheddaMarketExplorer is Ownable {
    struct Collection {
        address nftContract;
        string metadataURI;
        bool exists;
    }

    struct LikesDislikes {
        uint256 likes;
        uint256 dislikes;
    }

    struct CollectionWithLikes {
        Collection collection;
        LikesDislikes likesDislikes;
    }

    struct MarketItem {
        address nftContract;
        uint256 tokenID;
        string tokenURI;
        uint256 price;
        uint256 listingTime;
    }

    struct MarketItemWithLikes {
        MarketItem item;
        LikesDislikes likesDislikes;
    }

    struct NFTDetails {
        address nftContract;
        uint256 tokenID;
        string tokenURI;
    }

    ICheddaAddressRegistry public registry;

    // nft contract addres => number of likes
    mapping(address => uint256) public collectionLikes;

    // nft contract address => number of dislikes
    mapping(address => uint256) public collectionDislikes;

    // nft contract address => (token ID => number of likes)
    mapping(address => mapping(uint256 => uint256)) public itemLikes;

    // nft contract address => (token ID => number of dislikes)
    mapping(address => mapping(uint256 => uint256)) public itemDislikes;

    // user address => (nft contract address => user liked)
    mapping(address => mapping(address => bool)) public userLikedCollection;

    // user address => (nft contract address => user disliked)
    mapping(address => mapping(address => bool)) public userDislikedCollection;

    // user address => (nft contract address => (tokenId => user liked))
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public userLikedItem;

    // user address => (nft contract address => (tokenId => user disliked))
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public userDislikedItem;

    // minimum number of likes for item to be considered popular. Can be updated
    uint256 public popularItemMinumumLikes = 1;

    // minimum ration between likes:dislikes for item to be considered popular. n:1 ratio
    uint256 public popularItemRatio = 2;

    struct NFTPair {
        address nftContract;
        uint256 tokenID;
    }
    mapping(address => NFTPair[]) public itemsOwned;

    MarketItem[] public allItems;

    bytes4 private constant INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant INTERFACE_ID_ICHEDDA_NFT = 0x03ee438c;

    mapping(address => Collection) public collections;
    address[] public collectionList;

    // NFT address to market item
    mapping(address => MarketItem[]) public collectionItems;

    function updateRegistry(address registryAddress) public onlyOwner {
        registry = ICheddaAddressRegistry(registryAddress);
    }

    function likeCollection(address nftContract) public {
        require(
            !userLikedCollection[_msgSender()][nftContract],
            "Already liked"
        );
        require(
            !userDislikedCollection[_msgSender()][nftContract],
            "Already liked"
        );
        userLikedCollection[_msgSender()][nftContract] = true;
        collectionLikes[nftContract] += 1;

        ICheddaRewards rewards = ICheddaRewards(registry.rewards());
        rewards.issueRewards(Actions.Like, _msgSender());
    }

    function dislikeCollection(address nftContract) public {
        require(
            !userLikedCollection[_msgSender()][nftContract],
            "Already liked"
        );
        require(
            !userDislikedCollection[_msgSender()][nftContract],
            "Already liked"
        );
        userDislikedCollection[_msgSender()][nftContract] = true;
        collectionDislikes[nftContract] += 1;

        ICheddaRewards rewards = ICheddaRewards(registry.rewards());
        rewards.issueRewards(Actions.Dislike, _msgSender());
    }

    function likeItem(address nftContract, uint256 tokenId) public {
        require(
            !userLikedItem[_msgSender()][nftContract][tokenId],
            "Already liked"
        );
        require(
            !userDislikedItem[_msgSender()][nftContract][tokenId],
            "Already disliked"
        );
        userLikedItem[_msgSender()][nftContract][tokenId] = true;
        itemLikes[nftContract][tokenId] += 1;

        ICheddaRewards rewards = ICheddaRewards(registry.rewards());
        rewards.issueRewards(Actions.Like, _msgSender());
    }

    function dislikeItem(address nftContract, uint256 tokenId) public {
        require(
            !userLikedItem[_msgSender()][nftContract][tokenId],
            "Already liked"
        );
        require(
            !userDislikedItem[_msgSender()][nftContract][tokenId],
            "Already disliked"
        );
        userDislikedItem[_msgSender()][nftContract][tokenId] = true;
        itemDislikes[nftContract][tokenId] += 1;

        ICheddaRewards rewards = ICheddaRewards(registry.rewards());
        rewards.issueRewards(Actions.Dislike, _msgSender());
    }

    function getCollections()
        public
        view
        returns (CollectionWithLikes[] memory)
    {
        CollectionWithLikes[] memory returnList = new CollectionWithLikes[](
            collectionList.length
        );
        for (uint256 i = 0; i < collectionList.length; i++) {
            address nftAddress = collectionList[i];
            Collection memory c = collections[nftAddress];
            uint256 likes = collectionLikes[c.nftContract];
            uint256 dislikes = collectionDislikes[c.nftContract];
            returnList[i] = CollectionWithLikes({
                collection: c,
                likesDislikes: LikesDislikes({likes: likes, dislikes: dislikes})
            });
        }
        return returnList;
    }

    function itemsInCollection(address nftContract)
        public
        view
        returns (MarketItemWithLikes[] memory)
    {
        uint256 length = collectionItems[nftContract].length;
        MarketItemWithLikes[] memory items = new MarketItemWithLikes[](length);

        for (uint256 i = 0; i < length; i++) {
            MarketItem storage item = collectionItems[nftContract][i];
            uint256 likes = itemLikes[item.nftContract][item.tokenID];
            uint256 dislikes = itemDislikes[item.nftContract][item.tokenID];
            items[i] = MarketItemWithLikes({
                item: item,
                likesDislikes: LikesDislikes({likes: likes, dislikes: dislikes})
            });
        }
        return items;
    }

    function getCollectionDetails(address nftContract)
        public
        view
        returns (CollectionWithLikes memory)
    {
        Collection memory c = collections[nftContract];
        uint256 likes = collectionLikes[nftContract];
        uint256 dislikes = collectionDislikes[nftContract];
        return
            CollectionWithLikes({
                collection: c,
                likesDislikes: LikesDislikes({likes: likes, dislikes: dislikes})
            });
    }

    function getAllItems() public view returns (MarketItemWithLikes[] memory) {
        uint256 length = allItems.length;
        MarketItemWithLikes[] memory items = new MarketItemWithLikes[](length);
        for (uint256 i = 0; i < length; i++) {
            MarketItem storage item = allItems[i];
            uint256 likes = itemLikes[item.nftContract][item.tokenID];
            uint256 dislikes = itemDislikes[item.nftContract][item.tokenID];
            items[i] = MarketItemWithLikes({
                item: item,
                likesDislikes: LikesDislikes({likes: likes, dislikes: dislikes})
            });
        }
        return items;
    }

    function newlyListedItems(uint256 time)
        public
        view
        returns (MarketItemWithLikes[] memory)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < allItems.length; i++) {
            if (allItems[i].listingTime > time) {
                count++;
            }
        }
        MarketItemWithLikes[] memory newItems = new MarketItemWithLikes[](
            count
        );
        count = 0;
        for (uint256 i = 0; i < allItems.length; i++) {
            if (allItems[i].listingTime > time) {
                MarketItem storage item = allItems[i];
                uint256 likes = itemLikes[item.nftContract][item.tokenID];
                uint256 dislikes = itemDislikes[item.nftContract][item.tokenID];
                newItems[count++] = MarketItemWithLikes({
                    item: item,
                    likesDislikes: LikesDislikes({
                        likes: likes,
                        dislikes: dislikes
                    })
                });
            }
        }
        return newItems;
    }

    function popularItems() public view returns (MarketItemWithLikes[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allItems.length; i++) {
            MarketItem storage item = allItems[i];
            uint256 numberOfLikes = itemLikes[item.nftContract][item.tokenID];
            uint256 numberOfDislikes = itemDislikes[item.nftContract][
                item.tokenID
            ];
            if (
                numberOfLikes >= popularItemMinumumLikes && numberOfDislikes == 0
            ) {
                count++;
            } else if (
                numberOfLikes >= popularItemMinumumLikes &&
                numberOfLikes / numberOfDislikes > popularItemRatio
            ) {
                count++;
            }
        }

        MarketItemWithLikes[] memory popular = new MarketItemWithLikes[](count);
        count = 0;
        for (uint256 i = 0; i < allItems.length; i++) {
            MarketItem storage item = allItems[i];
            uint256 likes = itemLikes[item.nftContract][item.tokenID];
            uint256 dislikes = itemDislikes[item.nftContract][item.tokenID];
            if (likes >= popularItemMinumumLikes && dislikes == 0) {
                popular[count++] = MarketItemWithLikes({
                    item: allItems[i],
                    likesDislikes: LikesDislikes({
                        likes: likes,
                        dislikes: dislikes
                    })
                });
            } else if (
                likes >= popularItemMinumumLikes &&
                likes / dislikes > popularItemRatio
            ) {
                popular[count++] = MarketItemWithLikes({
                    item: allItems[i],
                    likesDislikes: LikesDislikes({
                        likes: likes,
                        dislikes: dislikes
                    })
                });
            }
        }
        return popular;
    }

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

    function getMarketItemWithLikes(address nftContract, uint256 tokenID)
        public
        view
        returns (MarketItemWithLikes memory)
    {
        MarketItem memory item = getMarketItem(nftContract, tokenID);
        uint256 likes = itemLikes[nftContract][tokenID];
        uint256 dislikes = itemDislikes[nftContract][tokenID];
        return
            MarketItemWithLikes({
                item: item,
                likesDislikes: LikesDislikes({likes: likes, dislikes: dislikes})
            });
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
                itemsOwned[seller][i] = itemsOwned[seller][
                    sellerItemsOwned - 1
                ];
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
