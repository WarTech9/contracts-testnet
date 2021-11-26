//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/CheddaAddressRegistry.sol";
import "./CheddaXP.sol";
import "hardhat/console.sol";

enum Actions {
    Like,
    Rate,
    Review,
    Vote,
    Other
}

interface ICheddaRewards {
   function issueRewards(Actions action, address user) external;
}

contract CheddaRewards is Context, Ownable, ICheddaRewards {

    event RewardIssued(Actions indexed a, uint256 indexed amount, address indexed user);

    CheddaAddressRegistry public registry;

    mapping(Actions => uint256) public pointsPerAction;

    uint256 public POINTS_PER_LIKE = 10;
    uint256 public POINTS_PER_RATE = 10;
    uint256 public POINTS_PER_REVIEW = 30;
    uint256 public POINTS_PER_VOTE = 50;
    uint256 public pointsPerOther = 1;

    modifier onlyExplorer() {
        require(
            _msgSender() == registry.dappStoreExplorer() ||
                _msgSender() == registry.marketExplorer(),
            "Not allowed: Only Explorer"
        );
        _;
    }

    constructor() {
        setRewards(Actions.Like, POINTS_PER_LIKE);
        setRewards(Actions.Rate, POINTS_PER_RATE);
        setRewards(Actions.Review, POINTS_PER_REVIEW);
        setRewards(Actions.Vote, POINTS_PER_VOTE);
    }

    function updateRegistry(address registryAddress) external onlyOwner {
        registry = CheddaAddressRegistry(registryAddress);
    }

    function setRewards(Actions action, uint256 points) public onlyOwner {
        require(points != 0, "Points can not be 0");
        pointsPerAction[action] = points;
    }

    function issueRewards(Actions action, address user)
        public
        override
    {
        require(user != address(0), "Address can not be 0");
        uint256 amount = pointsPerAction[action];
        require(amount != 0, "Amount can not be 0");
        CheddaXP(registry.cheddaXP()).mint(amount, user);

        emit RewardIssued(action, amount, user);
    }
}
