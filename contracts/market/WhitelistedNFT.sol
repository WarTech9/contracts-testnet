//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MarketNFT.sol";

interface IWhitelistedNFT {
   function whiteListAddress(address user, bool isWhitelisted) external;
   function isWhitelisted(address user) external returns (bool);
}

contract WhitelistedNFT is MarketNFT, IWhitelistedNFT {

    bool public whitelistOnly = true;
    uint256 public whitelistMintLimit  = 1;
    uint256 public publicMintLimit = 1;

    /// @dev address -> isWhitelisted
    mapping(address => bool) public whitelist;

    /// @dev address -> can manage the whitelist.
    /// this is used by the drops module to whitelist users who have won whitelist spots.
    mapping(address => bool) public whitelistManagers;

    modifier isWhitelistManager(address user) {
        if (user != owner() && !whitelistManagers[user]) {
            revert("Not authorized");
        }
        _;
    }

    constructor(
        uint256 _mintFee,
        address payable _feeReceipient,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) MarketNFT(_mintFee,
        _feeReceipient,
        _name,
        _symbol,
        _uri) {
        mintFee = _mintFee;
        feeReceipient = _feeReceipient;
        metadataURI = _uri;
    }

    /**
     @notice Mints a NFT AND when minting to a contract checks if the beneficiary is a 721 compatible
     @param mintAddress Recipient of the NFT
     @param tokenUri URI for the token being minted
     @return uint256 The token ID of the token that was minted
     */
    function mint(address mintAddress, string calldata tokenUri)
        public
        payable
        override
        returns (uint256) {
        if (whitelistOnly) {
            require(whitelist[_msgSender()], "Not whitelisted");
        }
        return super.mint(mintAddress, tokenUri);
    }

    function setWhiltelistOnly(bool _whitelistOnly) public onlyOwner() {
        whitelistOnly = _whitelistOnly;
    }

    function setPublicMintLimit(uint256 limit) public onlyOwner() {
        publicMintLimit = limit;
    }

    function setWhitelistMintLimit(uint256 limit) public onlyOwner() {
        whitelistMintLimit = limit;
    }

    function whiteListAddress(address user, bool shouldWhitelist) public override isWhitelistManager(msg.sender) {
        whitelist[user] = shouldWhitelist;
    }

    function isWhitelisted(address user) public override view returns (bool) {
        return whitelist[user];
    }

    function setWhitelistManager(address user, bool canManage) public onlyOwner() {
        whitelistManagers[user] = canManage;
    }

}