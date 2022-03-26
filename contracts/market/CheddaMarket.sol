//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
import "./CheddaAuction.sol";
import "./CheddaMarketExplorer.sol";
import "../common/CheddaAddressRegistry.sol";

struct Listing {
    address nftContract;
    uint256 tokenId;
    address payable seller;
    uint256 price;
}

struct Sale {
    address seller;
    address buyer;
    uint256 amountPaid;
    uint256 timestamp;
}

contract CheddaMarket is Ownable, ReentrancyGuard {

    event ItemListed(address indexed nftContract, uint256 indexed itemId, uint256 price);
    event ItemSold(address indexed nftContract, uint256 indexed itemId, uint256 price);
    event ListingCancelled(address indexed nftContract, uint256 indexed itemId);

    event MarketFeeUpdated(uint256 marketFee, address indexed updatedBy);

    /// @notice Market item listing.
    /// Note: commission is set when the listing is created, not at time of purchase so that
    /// any changes in commissions do not impact already listed items
    /// @dev Explain to a developer any extra details


    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // NFT contract address => (Token ID => auction)
    mapping(address => mapping(uint256 => CheddaAuction)) private auctions;

    // NFT contract address => (Token ID => Price)
    mapping(address => mapping(uint256 => Listing)) public listings;

    mapping(address => uint256[]) public tokenIdsForSale;

    // NFT contract address => Token ID => Sale Price
    mapping(address => mapping(uint256 => Sale[])) public sales;

    // NFT contract address => Token ID => Sale Price
    mapping(address => mapping(uint256 => uint256)) public offers;

    // All items ever listed, items do not get deleted.
    Listing[] public allListings;

    /// @notice Market fee in basis points. 
    /// For a fee of 1%, platform fee would have a value of 100
    uint256 public marketFee;

    address payable public feeRecipient;

    ICheddaAddressRegistry public registry;

    modifier onlyItemOwner(address nftContract, uint256 tokenId) {
        if (_isERC721(nftContract)) {
            IERC721 nft = IERC721(nftContract);
            require(nft.ownerOf(tokenId) == msg.sender, "Market: Not item owner");
        }
        _;
    }

    function updateRegistry(address registryAddress) public onlyOwner() {
        registry = ICheddaAddressRegistry(registryAddress);
    }

    function setMarketFee(uint256 newFee) public onlyOwner() {
        marketFee = newFee;
        emit MarketFeeUpdated(marketFee, _msgSender());
    }

    function setfeeRecipient(address payable newAddress) public onlyOwner() {
        feeRecipient = newAddress;
    }

    function addItemToMarket(address nftContract, uint256 tokenId) external onlyItemOwner(nftContract, tokenId) {
        CheddaMarketExplorer(registry.marketExplorer()).reportItemAdded(nftContract, tokenId, 0, _msgSender());
    }

    function listItemForSale(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external onlyItemOwner(nftContract, tokenId) {
        require(!_saleItemExists(nftContract, tokenId), "Market: Already listed");
        Listing memory listing = Listing(nftContract, tokenId, payable(_msgSender()), price);
        listings[nftContract][tokenId] = listing;
        allListings.push(listing);
        tokenIdsForSale[nftContract].push(tokenId);
        CheddaMarketExplorer(registry.marketExplorer()).reportListing(nftContract, tokenId, price);
        emit ItemListed(nftContract, tokenId, price);
    }

    function buyItem(address nftContract, uint256 tokenId) external payable nonReentrant() {
        require(_saleItemExists(nftContract, tokenId), "Market: Not for sale");
        Listing storage listing = listings[nftContract][tokenId];
        uint256 itemPrice = listing.price;
        require(msg.value >= itemPrice, "Market: Value < price");
        
        uint256 fee = _calculateFee(itemPrice);
        if (fee != 0) {
            feeRecipient.transfer(fee);
        }
        uint256 amountPaid = msg.value - fee;
        listing.seller.transfer(amountPaid);
        IERC721(nftContract).transferFrom(listing.seller, _msgSender(), tokenId);

        Sale memory newSale = Sale(listing.seller, _msgSender(), itemPrice, block.timestamp);
        sales[nftContract][tokenId].push(newSale);

        _delistItem(nftContract, tokenId);

        CheddaMarketExplorer(registry.marketExplorer()).reportMarketSale(nftContract, tokenId, amountPaid, listing.seller, _msgSender());

        emit ItemSold(nftContract, tokenId, itemPrice);
    }

    function cancelListing(address nftContract, uint256 tokenId)
        external
        onlyItemOwner(nftContract, tokenId)
    {
        require(_saleItemExists(nftContract, tokenId), "Market: Item not listed");
        _delistItem(nftContract, tokenId);
        CheddaMarketExplorer(registry.marketExplorer()).reportListingCancellation(nftContract, tokenId);
        emit ListingCancelled(nftContract, tokenId);
    }

    function listItemForAuction(
        address nftContract,
        uint256 tokenId,
        uint256 reserve,
        uint256 startTime,
        uint256 endTime
    ) public {}

    function placeBid(address nftContract, uint256 tokenId) external payable {}

    function cancelBid(address nftContract, uint256 tokenId) external {}

    function previousSales(address nftContract, uint256 tokenId) external view returns (Sale[] memory) {
        Sale[] memory items = sales[nftContract][tokenId];
        return items;
    }

    function itemsForSale(address nftContract) external view returns (Listing[] memory) {
        uint256 length = tokenIdsForSale[nftContract].length;
        Listing[] memory items = new Listing[](length);
        for (uint256 i = 0; i < length; i++) {
            Listing memory item = listings[nftContract][tokenIdsForSale[nftContract][i]];
            items[i] = item;
        }
        return items;
    }

    // private functions

    function _isERC721(address nftContract) internal view returns (bool) {
        return (IERC165(nftContract).supportsInterface(INTERFACE_ID_ERC721));
    }

    function _delistItem(address nftContract, uint256 tokenId) private {
        delete listings[nftContract][tokenId];
        (uint256 index, bool found) = _indexOfTokenId(nftContract, tokenId);
        if (found) {
            delete tokenIdsForSale[nftContract][index];
        }
    }

    function _indexOfTokenId(address nftContract, uint256 tokenId) private view returns (uint256, bool) {
        for (uint256 i = 0; i < tokenIdsForSale[nftContract].length; i++) {
            if (tokenIdsForSale[nftContract][i] == tokenId) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function _calculateFee(uint256 price) private view returns (uint256) {
        return price * marketFee / 1e4;
    }

    function _saleItemExists(address nftContract, uint256 tokenId)
        private view
        returns (bool)
    {
        return listings[nftContract][tokenId].seller != address(0);
    }

    function getAllListings() public view returns (Listing[] memory) {
        Listing[] memory toReturn = new Listing[](allListings.length);
        for (uint256 i = 0; i < allListings.length; i++) {
            toReturn[i] = allListings[i];
        }
        return toReturn;
    }
}
