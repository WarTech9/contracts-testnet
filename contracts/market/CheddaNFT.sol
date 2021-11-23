//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IMintPolicy.sol";

interface ICheddaNFT is IERC721 {
    /**
     * @dev Returns the URI containing the token metadata.
     */
    function metadataURI() external view returns (string memory);
}
contract CheddaNFT is ICheddaNFT, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIds;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal _tokenURIs;

    /// @notice Platform fee
    uint256 public mintFee;

    /// @dev TokenID -> Creator address
    mapping(uint256 => address) public minters;

    /// @notice Platform fee receipient
    address payable public feeReceipient;

    string public override metadataURI;

    /// @dev Events of the contract
    event Minted(
        uint256 tokenId,
        address beneficiary,
        string tokenUri,
        address minter
    );

    modifier tokenIdExists(uint256 tokenId) {
        require(_exists(tokenId), "NFT: tokenId does not exist");
        _;
    }

    constructor(
        uint256 _mintFee,
        address payable _feeReceipient,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        mintFee = _mintFee;
        feeReceipient = _feeReceipient;
        metadataURI = _uri;
    }

    function setMintFee(uint256 newMintFee) public onlyOwner {
        mintFee = newMintFee;
    }

    // function metadataURI() public view returns (string memory) {
    //     return _metadataURI;
    // }

    /**
     @notice Mints a NFT AND when minting to a contract checks if the beneficiary is a 721 compatible
     @param mintAddress Recipient of the NFT
     @param tokenUri URI for the token being minted
     @return uint256 The token ID of the token that was minted
     */
    function mint(address mintAddress, string calldata tokenUri)
        external
        payable
        returns (uint256)
    {
        require(msg.value >= mintFee, "NFT: Insufficient mint fee");
        require(bytes(tokenUri).length > 0, "NFT: tokenUri is empty");
        require(mintAddress != address(0), "NFT: Addr");

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        // Mint token and set token URI
        _safeMint(mintAddress, tokenId);
        _setTokenURI(tokenId, tokenUri);

        if (msg.value != 0) {
            feeReceipient.transfer(msg.value);
        }

        minters[tokenId] = msg.sender;

        emit Minted(tokenId, mintAddress, tokenUri, _msgSender());

        return tokenId;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        tokenIdExists(tokenId)
        returns (string memory)
    {
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
        tokenIdExists(tokenId)
    {
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
