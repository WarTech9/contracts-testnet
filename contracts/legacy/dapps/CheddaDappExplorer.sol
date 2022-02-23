//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CheddaDappStore.sol";
import "../../rewards/CheddaRewards.sol";
import "hardhat/console.sol";

struct Review {
    uint256 id;
    string contentURI;
    uint256 rating;
    uint256 timestamp;
    address author;
    int32 credibility;
    int32 spamCount;
}

struct ReviewWithVote {
    Review review;
    int32 myVote;
}

interface IStoreExplorer {
    function numberOfRatings(address contractAddress)
        external
        view
        returns (uint256);

    function averageRating(address contractAddress)
        external
        view
        returns (uint256);
}

contract CheddaDappExplorer is Ownable, IStoreExplorer {
    event ReviewAdded(address indexed contractAddress, address indexed user, uint256 rating);
    event RatingAdded(
        address indexed contractAddress,
        address indexed user,
        uint256 rating
    );
    event VotedOnReview(address indexed contractAddress, address indexed user, uint256 indexed reviewId, int32 vote);

    CheddaAddressRegistry public registry;

    // Dapp address => rating
    mapping(address => uint256) public ratings;

    /*
    Dapp contract address => number of ratings dapp has received.
     */
    mapping(address => uint256) public ratingsCount;

    // dapp address => User address => rating
    mapping(address => mapping(address => uint256)) public userRatings;

    // dapp address => Review[]
    mapping(address => Review[]) public reviews;

    uint256 public reviewsCount;

    // dapp address => (user address => index in `reviews` array)
    mapping(address => mapping(address => uint256)) public myReviews;

    // user => reviewId => vote
    mapping(address => mapping(uint256 => int32)) public reviewVotes;

    uint16 public constant RATING_SCALE = 100;
    uint16 public constant MAX_RATING = 500;

    modifier dappExists(address contractAddress) {
        require(
            CheddaDappStore(registry.dappStore())
                .getDapp(contractAddress)
                .contractAddress != address(0),
            "Dapp does not exist"
        );
        _;
    }

    function updateRegistry(address registryAddress) external onlyOwner {
        registry = CheddaAddressRegistry(registryAddress);
        console.log("updating registry to %s", registryAddress);
    }

    function addReview(
        address contractAddress,
        string memory reviewDataURI,
        uint256 rating
    ) public dappExists(contractAddress) {
        require(
            myReviews[contractAddress][_msgSender()] == 0,
            "Already reviewed"
        );
        Review memory review = Review({
            id: ++reviewsCount,
            contentURI: reviewDataURI,
            rating: rating,
            timestamp: block.timestamp,
            author: _msgSender(),
            credibility: 0,
            spamCount: 0
        });
        addRating(contractAddress, rating);
        reviews[contractAddress].push(review);
        myReviews[contractAddress][_msgSender()] = reviewsCount;

        issueRewards(Actions.Review, _msgSender());
        emit ReviewAdded(contractAddress, _msgSender(), rating);
    }

    function getReviews(address contractAddress)
        public
        view
        dappExists(contractAddress)
        returns (Review[] memory)
    {
        return reviews[contractAddress];
    }

    function getReviewsWithVotes(address contractAddress)
        public
        view
        dappExists(contractAddress)
        returns (ReviewWithVote[] memory)
    {
        ReviewWithVote[] memory result = new ReviewWithVote[](reviews[contractAddress].length);
        for (uint256 i = 0; i < result.length; i++) {
            Review storage review = reviews[contractAddress][i];
            result[i] = ReviewWithVote({
                review: review,
                myVote: reviewVotes[_msgSender()][review.id]
            });
        }
        return result;
    }

    function getReviewsBetween(
        address contractAddress,
        uint256 start,
        uint256 end
    ) public view dappExists(contractAddress) returns (Review[] memory) {
        Review[] memory _reviews = reviews[contractAddress];
        uint8 numberOfMatches = 0;
        for (uint256 index = 0; index < _reviews.length; index++) {
            Review memory dapp = _reviews[index];
            if (dapp.timestamp > start && dapp.timestamp < end) {
                numberOfMatches++;
            }
        }
        return _reviews;
    }

    function getLastReviews(uint256 count, address contractAddress)
        external
        view
        dappExists(contractAddress)
        returns (Review[] memory)
    {
        if (reviews[contractAddress].length <= count) {
            return reviews[contractAddress];
        } else {
            Review[] memory _reviews = new Review[](count);
            uint256 length = reviews[contractAddress].length;
            uint256 j = 0;
            for (uint256 i = length - count; i < length; i++) {
                _reviews[j++] = reviews[contractAddress][i];
            }
            return _reviews;
        }
    }

    function voteOnReview(
        address contractAddress,
        uint256 reviewId,
        int32 vote
    ) external dappExists(contractAddress) {
        require(vote == 1 || vote == -1, "Invalid vote");
        require(reviewVotes[_msgSender()][reviewId] == 0, "Already voted");
        Review[] storage _reviews = reviews[contractAddress];
        bool reviewFound = false;

        for (uint256 i = 0; i < _reviews.length; i++) {
            if (_reviews[i].id == reviewId) {
                if (_reviews[i].author == _msgSender()) {
                    revert("Invalid review");
                }
                _reviews[i].credibility += vote;
                reviewFound = true;
                break;
            }
        }
        if (reviewFound) {
            reviewVotes[_msgSender()][reviewId] = vote;
            issueRewards(vote == 1 ? Actions.Upvote: Actions.Downvote, _msgSender());

            emit VotedOnReview(contractAddress, _msgSender(), reviewId, vote);
        }
    }

    function addRating(address contractAddress, uint256 rating)
        public
        dappExists(contractAddress)
    {
        require(userRatings[contractAddress][msg.sender] == 0, "Already rated");
        require(rating != 0, "Rating can not be 0");
        require(
            rating % RATING_SCALE == 0 && rating <= MAX_RATING,
            "Invalid rating"
        );
        userRatings[contractAddress][msg.sender] = rating;
        ratings[contractAddress] += rating;
        ratingsCount[contractAddress] += 1;

        issueRewards(Actions.Rate, _msgSender());
        emit RatingAdded(contractAddress, _msgSender(), rating);
    }

    function numberOfRatings(address contractAddress)
        public
        view
        override
        dappExists(contractAddress)
        returns (uint256)
    {
        return ratingsCount[contractAddress];
    }

    function averageRating(address contractAddress)
        public
        view
        override
        dappExists(contractAddress)
        returns (uint256)
    {
        uint256 count = ratingsCount[contractAddress];
        if (count == 0) {
            return 0;
        }
        return ratings[contractAddress] / count;
    }

    function myRating(address contractAddress)
        public
        view
        dappExists(contractAddress)
        returns (uint256)
    {
        return userRatings[contractAddress][msg.sender];
    }

    function issueRewards(Actions action, address recipient) private {
        ICheddaRewards rewards = ICheddaRewards(registry.rewards());
        rewards.issueRewards(action, recipient);
    }
}
