//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../legacy/rewards/CheddaRewards.sol";
import "../common/CheddaAddressRegistry.sol";
import "./CheddaMarket.sol";
import "./MarketNFT.sol";

interface IMarketExplorer {
    function itemTransfered(address nftContract, uint256 tokenID, address from, address to, uint256 amount) external;
}

// market explorer
contract CheddaMarketExplorer is Ownable, IMarketExplorer {
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

    struct NFTDetailsWithLikes {
        NFTDetails item;
        LikesDislikes likesDislikes;
    }

    struct OwnedItem {
        address nftContract;
        uint256 tokenID;
        uint256 lastPrice;
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
    // +1 for like -1 for dislike
    mapping(address => mapping(address => int8)) public userLikedCollection;

    // user address => (nft contract address => (tokenId => user liked))
    // +1 for like -1 for dislike
    mapping(address => mapping(address => mapping(uint256 => int8)))
        public userLikedItem;

    // minimum number of likes for item to be considered popular. Can be updated
    uint256 public popularItemMinumumLikes = 1;

    // minimum ration between likes:dislikes for item to be considered popular. n:1 ratio
    uint256 public popularItemRatio = 2;

    uint256 private constant MAX_UINT =  2 ** 256 - 1;

    mapping(address => OwnedItem[]) public itemsOwned;


    // All items currently listed in the market.
    // NOTE: index 0 is a dummy item. Looping through this array must start from index 1
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
            userLikedCollection[_msgSender()][nftContract] == 0,
            "Already liked"
        );

        userLikedCollection[_msgSender()][nftContract] = 1;
        collectionLikes[nftContract] += 1;

        ICheddaRewards rewards = ICheddaRewards(registry.rewards());
        rewards.issueRewards(Actions.Like, _msgSender());
    }

    function dislikeCollection(address nftContract) public {
        require(
            userLikedCollection[_msgSender()][nftContract] == 0,
            "Already liked"
        );

        userLikedCollection[_msgSender()][nftContract] = -1;
        collectionDislikes[nftContract] += 1;

        ICheddaRewards rewards = ICheddaRewards(registry.rewards());
        rewards.issueRewards(Actions.Dislike, _msgSender());
    }

    function likeItem(address nftContract, uint256 tokenId) public {
        require(
            userLikedItem[_msgSender()][nftContract][tokenId] == 0,
            "Already liked"
        );

        userLikedItem[_msgSender()][nftContract][tokenId] = 1;
        itemLikes[nftContract][tokenId] += 1;

        ICheddaRewards rewards = ICheddaRewards(registry.rewards());
        rewards.issueRewards(Actions.Like, _msgSender());
    }

    function dislikeItem(address nftContract, uint256 tokenId) public {
        require(
            userLikedItem[_msgSender()][nftContract][tokenId] == 0,
            "Already liked"
        );

        userLikedItem[_msgSender()][nftContract][tokenId] = -1;
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
            LikesDislikes memory likesDislikes = _collectionLikesDislikes(nftAddress);
            returnList[i] = CollectionWithLikes({
                collection: c,
                likesDislikes: likesDislikes
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
            LikesDislikes memory likesDislikes = _itemLikesDislikes(item.nftContract, item.tokenID);
            items[i] = MarketItemWithLikes({
                item: item,
                likesDislikes: likesDislikes
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
        LikesDislikes memory likesDislikes = _collectionLikesDislikes(nftContract);
        return
            CollectionWithLikes({
                collection: c,
                likesDislikes: likesDislikes
            });
    }

    function getAllItems() public view returns (MarketItemWithLikes[] memory) {
        uint256 length = allItems.length;
        MarketItemWithLikes[] memory items = new MarketItemWithLikes[](length);
        for (uint256 i = 0; i < length; i++) {
            MarketItem storage item = allItems[i];
            LikesDislikes memory likesDislikes = _itemLikesDislikes(item.nftContract, item.tokenID);
            items[i] = MarketItemWithLikes({
                item: item,
                likesDislikes: likesDislikes
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
                LikesDislikes memory likesDislikes = _itemLikesDislikes(item.nftContract, item.tokenID);
                newItems[count++] = MarketItemWithLikes({
                    item: item,
                    likesDislikes: likesDislikes
                });
            }
        }
        return newItems;
    }

    function popularItems() public view returns (MarketItemWithLikes[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allItems.length; i++) {
            MarketItem storage item = allItems[i];
            LikesDislikes memory likesDislikes = _itemLikesDislikes(item.nftContract, item.tokenID);
            if (
                likesDislikes.likes >= popularItemMinumumLikes && likesDislikes.dislikes == 0
            ) {
                count++;
            } else if (
                likesDislikes.likes >= popularItemMinumumLikes &&
                likesDislikes.likes / likesDislikes.dislikes > popularItemRatio
            ) {
                count++;
            }
        }

        MarketItemWithLikes[] memory popular = new MarketItemWithLikes[](count);
        count = 0;
        for (uint256 i = 0; i < allItems.length; i++) {
            MarketItem storage item = allItems[i];
            LikesDislikes memory likesDislikes = _itemLikesDislikes(item.nftContract, item.tokenID);

            if (likesDislikes.likes >= popularItemMinumumLikes && likesDislikes.dislikes == 0) {
                popular[count++] = MarketItemWithLikes({
                    item: allItems[i],
                    likesDislikes: likesDislikes
                });
            } else if (
                likesDislikes.likes >= popularItemMinumumLikes &&
                likesDislikes.likes / likesDislikes.dislikes > popularItemRatio
            ) {
                popular[count++] = MarketItemWithLikes({
                    item: allItems[i],
                    likesDislikes: likesDislikes
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
        LikesDislikes memory likesDislikes = _itemLikesDislikes(nftContract, tokenID);
        return
            MarketItemWithLikes({
                item: item,
                likesDislikes: likesDislikes
            });
    }

    // todo: add marketOnly modifier
    function reportListing(
        address nftContract,
        uint256 tokenID,
        uint256 price
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
            // todo: fix the _isMarketNFT check
            // if (_isMarketNFT(nftContract)) {
            IMarketNFT nftMetadata = IMarketNFT(nftContract);
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
    }

    function reportItemAdded(        
        address nftContract,
        uint256 tokenID,
        uint256 amount,
        address owner
        ) public {
            itemsOwned[owner].push(OwnedItem(nftContract, tokenID, amount));
        }

    // todo: add marketOnly modifier
    function reportMarketSale(
        address nftContract,
        uint256 tokenID,
        uint256 amountPaid,
        address seller,
        address buyer
    ) public {
        uint256 index = MAX_UINT;
        for (uint256 i = 0; i < allItems.length; i++) {
            if (
                allItems[i].nftContract == nftContract &&
                allItems[i].tokenID == tokenID
            ) {
                index = i;
                break;
            }
        }
        if (index != MAX_UINT) {
            allItems[index] = allItems[allItems.length - 1];
            allItems.pop();
        }

        // // update itemsOwned
        itemTransfered(nftContract, tokenID, seller, buyer, amountPaid);   
    }

    function itemTransfered(address nftContract, uint256 tokenID, address from, address to, uint256 amountPaid) public override {
       uint256 sellerItemsOwned = itemsOwned[from].length;
        for (uint256 i = 0; i < sellerItemsOwned; i++) {
            OwnedItem memory item = itemsOwned[from][i];
            if (item.nftContract == nftContract && item.tokenID == tokenID) {
                itemsOwned[from][i] = itemsOwned[from][
                    sellerItemsOwned - 1
                ];
                itemsOwned[from].pop();
                break;
            }
        }

        itemsOwned[to].push(OwnedItem(nftContract, tokenID, amountPaid)); 
    }

    function reportListingCancellation(address nftContract, uint256 tokenID) public {
        uint256 index = MAX_UINT;
        for (uint256 i = 0; i < allItems.length; i++) {
            if (
                allItems[i].nftContract == nftContract &&
                allItems[i].tokenID == tokenID
            ) {
                index = i;
                break;
            }
        }
        if (index != MAX_UINT) {
            allItems[index] = allItems[allItems.length - 1];
            allItems.pop();
        }
    }

    function getItemsOwned(address user)
        public
        view
        returns (NFTDetailsWithLikes[] memory)
    {
        uint256 arraySize = itemsOwned[user].length;
        NFTDetailsWithLikes[] memory usersItems = new NFTDetailsWithLikes[](arraySize);
        for (uint256 i = 0; i < arraySize; i++) {
            OwnedItem storage currentItem = itemsOwned[user][i];
            string memory tokenURI = IERC721Metadata(currentItem.nftContract)
                .tokenURI(currentItem.tokenID);
            NFTDetails memory details = NFTDetails(
                currentItem.nftContract,
                currentItem.tokenID,
                tokenURI
            );
            LikesDislikes memory likesDislikes = _itemLikesDislikes(currentItem.nftContract, currentItem.tokenID);
            usersItems[i] = NFTDetailsWithLikes({
                item: details,
                likesDislikes: likesDislikes
            });
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

    function _itemLikesDislikes(address nftContract, uint256 tokenID) private view returns (LikesDislikes memory) {
        uint256 likes = itemLikes[nftContract][tokenID];
        uint256 dislikes = itemDislikes[nftContract][tokenID];
        return LikesDislikes({
            likes: likes,
            dislikes: dislikes
        });
    }

    function _collectionLikesDislikes(address nftContract) private view returns (LikesDislikes memory) {
        uint256 likes = collectionLikes[nftContract];
        uint256 dislikes = collectionDislikes[nftContract];
        return LikesDislikes({
            likes: likes,
            dislikes: dislikes
        });
    }

    function _isMarketNFT(address nftContract) internal view returns (bool) {
        return (
            IMarketNFT(nftContract).supportsInterface(INTERFACE_ID_ICHEDDA_NFT)
        );
    }
}
