//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
import "./CheddaAuction.sol";
import "./CheddaMarketExplorer.sol";

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
}

contract CheddaMarket is Ownable, ReentrancyGuard {

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

    Listing[] public allListings;

    /// @notice Market fee in basis points. 
    /// For a fee of 1%, platform fee would have a value of 100
    uint256 public marketFee;

    address payable public feeRecipient;

    CheddaMarketExplorer public explorer;

    modifier onlyItemOwner(address nftContract, uint256 tokenId) {
        if (_isERC721(nftContract)) {
            IERC721 nft = IERC721(nftContract);
            require(nft.ownerOf(tokenId) == msg.sender, "Market: Not item owner");
        }
        _;
    }

    function updateMarketExplorer(address explorerAddress) public {
        explorer = CheddaMarketExplorer(explorerAddress);
    }

    function setMarketFee(uint256 newFee) public onlyOwner() {
        marketFee = newFee;
    }

    function setfeeRecipient(address payable newAddress) public onlyOwner() {
        feeRecipient = newAddress;
    }

    function listItemForSale(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external onlyItemOwner(nftContract, tokenId) {
        require(!_saleItemExists(nftContract, tokenId), "Market: Already listed");
        IERC721(nftContract).transferFrom(_msgSender(), address(this), tokenId);
        Listing memory listing = Listing(nftContract, tokenId, payable(_msgSender()), price);
        listings[nftContract][tokenId] = listing;
        allListings.push(listing);
        tokenIdsForSale[nftContract].push(tokenId);
        explorer.reportListing(nftContract, tokenId, price, _msgSender());
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
        IERC721(nftContract).transferFrom(address(this), _msgSender(), tokenId);

        Sale memory newSale = Sale(listing.seller, _msgSender(), itemPrice);
        sales[nftContract][tokenId].push(newSale);
        explorer.reportMarketSale(nftContract, tokenId, listing.seller, _msgSender());

        _delistItem(nftContract, tokenId);
    }

    function cancelSale(address nftContract, uint256 tokenId)
        external
        onlyItemOwner(nftContract, tokenId)
    {
        require(_saleItemExists(nftContract, tokenId), "Market: Cancel item not listed");
        _delistItem(nftContract, tokenId);
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
