//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../common/CheddaAddressRegistry.sol";
import "../common/CheddaEntropy.sol";
import "../legacy/rewards/CheddaXP.sol";
import "./WhitelistedNFT.sol";

struct DropEntry {
    address user;
    uint256 slot;
    uint256 tickets;
}
interface ICheddaDrop {
    function start() external returns (uint);
    function end() external returns (uint);
    function metadataURI() external returns (string memory);
    function enter() external;
    function pickWinners() external;
    function getEntries() external view returns (DropEntry[] memory);
}

contract NFTWhitelistDrop is Ownable, ICheddaDrop {

    uint256 public override start;
    uint256 public override end;
    uint256 public currentSlot;
    uint256 public numberOfWinners;

    string public override metadataURI;

    mapping (address => bool) public hasEntered;
    address public nftContract;
    ICheddaAddressRegistry public registry;

    DropEntry[] public entries;

    constructor(uint256 _start, uint256 _end, address _nft, string memory _uri) {
        // todo: uncomment. Commented for testing basic functionality
        // require(_start < end && start > block.timestamp && end > block.timestamp,
        // "Drop: Invalid times");
        // require(IWhitelistedNFT(_nft).isWhitelisted(address(this)), "Drop: Not whitelisted");
        start = _start;
        end = _end;
        nftContract = _nft;
        metadataURI = _uri;
    }

    modifier isOpen() {
        require (block.timestamp >= start && block.timestamp < end, "Drop: Not open");
        _;
    }

    modifier hasEnded() {
        require(block.timestamp > end, "Drop: Not ended");
        _;
    }

    function updateRegistry(address registryAddress) external onlyOwner() {
        registry = ICheddaAddressRegistry(registryAddress);
    }

    function enter() public override isOpen() {
        // todo: implement slot count based on Chedda NFT balance
        require(!hasEntered[_msgSender()], "Drop: already entered");
        require(CheddaXP(registry.cheddaXP()).balanceOf(_msgSender()) > 0,
        "Drop: CheddaXP required");
        IEntropy(registry.entropy()).addEntropy();
        hasEntered[_msgSender()] = true;
        uint256 ticketCount = 1; // todo: get ticket count from Chedda NFT rank
        currentSlot += ticketCount;
        DropEntry memory entry = DropEntry({
            user: msg.sender,
            slot: currentSlot,
            tickets: ticketCount
        });
        entries.push(entry);
    }

    function pickWinners() public override hasEnded() onlyOwner() {
        for (uint256 i = 0; i < numberOfWinners; i++) {
            address winner = pickWinner();
            IWhitelistedNFT(nftContract).whiteListAddress(winner, true);
        }
    }

    function getEntries() public override view returns (DropEntry[] memory) {
        return entries;
    }

    function pickWinner() private view hasEnded() returns (address) {
       uint256 winningTicket = randomNumber(currentSlot);
       for (uint256 i = 0; i < entries.length; i++) {
           DropEntry storage entry = entries[i];
           if (entry.slot >= winningTicket) {
               return entry.user;
           }
       }
       return address(0);
    }

    function myTickets() public view returns (uint256) {
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].user == _msgSender()) {
                return entries[i].tickets;
            }
        }
        return 0;
    }

    function randomNumber(uint256 max) private view returns (uint256) {
        return IEntropy(registry.entropy()).randomNumber(max);
    }

}