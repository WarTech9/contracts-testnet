//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract CheddaAuction is Context, Ownable {
    // static
    uint256 public bidIncrement;
    uint256 public startBlock;
    uint256 public endBlock;

    // state
    bool public canceled;
    uint256 public highestBindingBid;
    address public highestBidder;
    mapping(address => uint256) public fundsByBidder;
    bool private ownerHasWithdrawn;

    event LogBid(
        address bidder,
        uint256 bid,
        address highestBidder,
        uint256 highestBid,
        uint256 highestBindingBid
    );
    event LogWithdrawal(
        address withdrawer,
        address withdrawalAccount,
        uint256 amount
    );
    event LogCanceled();

    modifier onlyAfterStart() {
        require(block.number < startBlock, "Auction: Not yet started");
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.number > endBlock, "Auction: already ended");
        _;
    }

    modifier onlyNotCanceled() {
        require(!canceled, "Auction: Already cancelled");
        _;
    }

    modifier onlyEndedOrCanceled() {
        require(block.number < endBlock && !canceled, "Auction: In Progress");
        _;
    }

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _bidIncrement
    ) {
        require(_startBlock <= _endBlock, "Auction: Invalid start/end");
        require(_startBlock > block.number, "Auction: Invalid startBlock");
        require(owner() != address(0), "Auction: Owner == address(0)");

        bidIncrement = _bidIncrement;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function getHighestBid() public view returns (uint256) {
        return fundsByBidder[highestBidder];
    }

    function placeBid()
        public
        payable
        onlyAfterStart
        onlyBeforeEnd
        onlyNotCanceled
        returns (bool success)
    {
        // reject payments of 0 ETH
        require (msg.value != 0, "Auction: Invalid bid amount");
        require(msg.sender != owner(), "Auctoin: Owner can't bid");

        // calculate the user's total bid based on the current amount they've sent to the contract
        // plus whatever has been sent with this transaction
        uint256 newBid = fundsByBidder[msg.sender] + msg.value;

        // if the user isn't even willing to overbid the highest binding bid, there's nothing for us
        // to do except revert the transaction.
        require(newBid >= highestBindingBid, "Auction: Bid amount too low");

        // grab the previous highest bid (before updating fundsByBidder, in case msg.sender is the
        // highestBidder and is just increasing their maximum bid).
        uint256 highestBid = fundsByBidder[highestBidder];

        fundsByBidder[msg.sender] = newBid;

        if (newBid <= highestBid) {
            // if the user has overbid the highestBindingBid but not the highestBid, we simply
            // increase the highestBindingBid and leave highestBidder alone.

            // note that this case is impossible if msg.sender == highestBidder because you can never
            // bid less ETH than you've already bid.

            highestBindingBid = _min(newBid + bidIncrement, highestBid);
        } else {
            // if msg.sender is already the highest bidder, they must simply be wanting to raise
            // their maximum bid, in which case we shouldn't increase the highestBindingBid.

            // if the user is NOT highestBidder, and has overbid highestBid completely, we set them
            // as the new highestBidder and recalculate highestBindingBid.

            if (msg.sender != highestBidder) {
                highestBidder = msg.sender;
                highestBindingBid = _min(newBid, highestBid + bidIncrement);
            }
            highestBid = newBid;
        }

        emit LogBid(
            msg.sender,
            newBid,
            highestBidder,
            highestBid,
            highestBindingBid
        );
        return true;
    }

    function cancelAuction()
        public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        returns (bool success)
    {
        canceled = true;
        emit LogCanceled();
        return true;
    }

    function withdraw() public onlyEndedOrCanceled returns (bool success) {
        address withdrawalAccount;
        uint256 withdrawalAmount;

        if (canceled) {
            // if the auction was canceled, everyone should simply be allowed to withdraw their funds
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
        } else {
            // the auction finished without being canceled

            if (msg.sender == owner()) {
                // the auction's owner should be allowed to withdraw the highestBindingBid
                withdrawalAccount = highestBidder;
                withdrawalAmount = highestBindingBid;
                ownerHasWithdrawn = true;
            } else if (msg.sender == highestBidder) {
                // the highest bidder should only be allowed to withdraw the difference between their
                // highest bid and the highestBindingBid
                withdrawalAccount = highestBidder;
                if (ownerHasWithdrawn) {
                    withdrawalAmount = fundsByBidder[highestBidder];
                } else {
                    withdrawalAmount =
                        fundsByBidder[highestBidder] -
                        highestBindingBid;
                }
            } else {
                // anyone who participated but did not win the auction should be allowed to withdraw
                // the full amount of their funds
                withdrawalAccount = msg.sender;
                withdrawalAmount = fundsByBidder[withdrawalAccount];
            }
        }

        if (withdrawalAmount == 0) {
            revert("Auction: Invalid amount");
        }

        fundsByBidder[withdrawalAccount] -= withdrawalAmount;

        // send the funds
        bool sent = payable(msg.sender).send(withdrawalAmount);
        if (!sent) {
            revert("Auction: Failed to withdraw");
        }
        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        if (a < b) return a;
        return b;
    }
}
