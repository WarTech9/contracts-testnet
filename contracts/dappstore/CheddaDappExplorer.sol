//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CheddaDappStore.sol";
import "../chedda/CheddaRewards.sol";
import "hardhat/console.sol";

struct Review {
    address contractAddress;
    string reviewURI;
    uint256 rating;
    uint256 timestamp;
    address author;
}

contract CheddaDappExplorer is Context, Ownable {
    event ReviewAdded(address indexed contractAddress, address indexed user);
    event RatingAdded(address indexed contractAddress, address indexed user, uint256 rating);

    IStore private _dappStore;
    CheddaAddressRegistry public registry;

    // Dapp address => rating
    mapping(address => uint256) public ratings;

    // dapp address => User address => rating
    mapping(address => mapping(address => uint256)) public userRatings;

    // dapp address => Review[]
    mapping(address => Review[]) public reviews;

    // dapp address => (user address => index in `reviews` array)
    mapping(address => mapping(address => uint256)) public myReviews;

    /*
    Dapp contract address => number of ratings dapp has received.
     */
    mapping(address => uint256) public numberOfRatings;

    uint16 public constant RATING_SCALE = 100;
    uint16 public constant MAX_RATING = 500;

    constructor(IStore store) {
        _dappStore = store;
    }

    modifier dappExists(address contractAddress) {
        require(
            _dappStore.getDapp(contractAddress).contractAddress != address(0),
            "Dapp does not exist"
        );
        _;
    }


    function updateRegistry(address registryAddress) external onlyOwner() {
        registry = CheddaAddressRegistry(registryAddress);
        console.log("updating registry to %s", registryAddress);
    }

    function addReview(address contractAddress, string memory reviewDataURI, uint256 rating)
        public
        dappExists(contractAddress)
    {
        Review memory review = Review(
            contractAddress,
            reviewDataURI,
            rating,
            block.timestamp,
            msg.sender
        );
        this.addRating(contractAddress, rating);
        reviews[contractAddress].push(review);
        emit ReviewAdded(contractAddress, _msgSender());
    }

    function getReviews(address contractAddress)
        public
        view
        dappExists(contractAddress)
        returns (Review[] memory)
    {
        return reviews[contractAddress];
    }

    function getReviewsBetween(
        address contractAddress,
        uint256 start,
        uint256 end
    ) public view
        dappExists(contractAddress)
     returns (Review[] memory) {
        Review[] memory __dapps = reviews[contractAddress];
        uint8 numberOfMatches = 0;
        for (uint256 index = 0; index < __dapps.length; index++) {
            Review memory dapp = __dapps[index];
            if (dapp.timestamp > start && dapp.timestamp < end) {
                numberOfMatches++;
            }
        }
        return __dapps;
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
        numberOfRatings[contractAddress] += 1;

        ICheddaRewards rewards = ICheddaRewards(registry.rewards());
        rewards.issueRewards(Actions.Rate, _msgSender());
        emit RatingAdded(contractAddress, _msgSender(), rating);
    }

    function averageRating(address contractAddress)
        public
        view
        dappExists(contractAddress)
        returns (uint256)
    {
        uint256 ratingsCount = numberOfRatings[contractAddress];
        if (ratingsCount == 0) {
          return 0;
        }
        return ratings[contractAddress] / ratingsCount;
    }

    function myRating(address contractAddress)
    public
    view
    dappExists(contractAddress)
    returns (uint256)
    {
      return  userRatings[contractAddress][msg.sender];
    }
}
