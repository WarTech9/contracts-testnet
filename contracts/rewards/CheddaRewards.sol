//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/CheddaAddressRegistry.sol";
import "./CheddaCampaign.sol";
import "./CheddaNFT.sol";
import "./CheddaXP.sol";
import "hardhat/console.sol";

enum Actions {
    Upvote,
    Downvote,
    Like,
    Dislike,
    Rate,
    Review,
    Vote,
    Other
}

interface ICheddaRewards {
   function issueRewards(Actions action, address user) external;
}

/// @title CheddaRewards. 
/// @notice Manages CheddaXP and Chedda NFT rewards on the platform.
contract CheddaRewards is Ownable, ICheddaRewards {

    event RewardsIssued(Actions indexed a, uint256 indexed amount, address indexed user);
    event RewardsSlashed(uint256 amount, address indexed user);

    // Rewards issued in campaign
    struct UserRewards {
        address user;
        uint256 points;
        CheddaNFT.Rank rank;
    }

    CheddaAddressRegistry public registry;

    address[] public epochs;
    mapping(Actions => uint256) public pointsPerAction;

    uint8 public boardSize = 100;
    uint256 public minimumPointsForReward = 0;

    uint256 public constant POINTS_PER_DOWNVOTE = 2;
    uint256 public constant POINTS_PER_UPVOTE = 2;
    uint256 public constant POINTS_PER_LIKE = 10;
    uint256 public constant POINTS_PER_DISLIKE = 10;
    uint256 public constant POINTS_PER_RATE = 10;
    uint256 public constant POINTS_PER_REVIEW = 20;
    uint256 public constant POINTS_PER_VOTE = 30;

    uint256 public constant RANK_GODFATHER = 0;
    uint256 public constant RANK_BOSS = 0;
    uint256 public constant RANK_UNDERBOSS = 1;
    uint256 public constant RANK_CONSIGLIERE = 5;
    uint256 public constant RANK_CAPOREGIME = 10;
    uint256 public constant RANK_SOLDIER = 20;
    uint256 public constant RANK_ASSOCIATE = 100;

    int256 public slashPerDownvote = -2;

    modifier onlyExplorer() {
        require(
            _msgSender() == registry.dappStoreExplorer() ||
                _msgSender() == registry.marketExplorer(),
            "Not allowed: Only Explorer"
        );
        _;
    }

    constructor() {
        setRewards(Actions.Upvote, POINTS_PER_UPVOTE);
        setRewards(Actions.Downvote, POINTS_PER_UPVOTE);
        setRewards(Actions.Like, POINTS_PER_LIKE);
        setRewards(Actions.Dislike, POINTS_PER_LIKE);
        setRewards(Actions.Rate, POINTS_PER_RATE);
        setRewards(Actions.Review, POINTS_PER_REVIEW);
        setRewards(Actions.Vote, POINTS_PER_VOTE);
    }

    function updateRegistry(address registryAddress) external onlyOwner {
        registry = CheddaAddressRegistry(registryAddress);
    }

    /// @notice Returns current leaderboard. If an poch is not currently in progress,
    /// returns the leaderboard of the previous epoch
    /// @return UserRewards sorted list of users, points and max reward.
    function leaderboard() external view returns(UserRewards[] memory) {
        address epoch = currentEpoch();
        if (epoch == address(0)) {
            epoch = lastEpoch();
        }
        if (epoch == address(0)) {
            return new UserRewards[](0);
        }

        AddressWithPoints[] memory sortedAddresses = CheddaCampaign(epoch).sortedBoard();
        UserRewards[] memory rewards = new UserRewards[](sortedAddresses.length);
        for (uint256 i = 0; i < sortedAddresses.length; i++) {
            rewards[i] = UserRewards(
                sortedAddresses[i].user, 
                sortedAddresses[i].points,
                rank(i)
                );
        }
        return rewards;
    }
    
    /// @notice Sets the number of points to reward per action
    /// @param action action to set points for
    /// @param points number of points
    function setRewards(Actions action, uint256 points) public onlyOwner () {
        require(points != 0, "Points can not be 0");
        pointsPerAction[action] = points;
    }

    /// @notice Rewards user for action performed.
    /// @dev Can only be called from MarketExplorer or DappstoreExplorer
    /// @param action Action user performed. Is used to determine number of XP to issue.
    /// @param user Address of user that performed action.
    function issueRewards(Actions action, address user)
        public
        override
        onlyExplorer()
    {
        require(user != address(0), "Address can not be 0");
        uint256 amount = pointsPerAction[action];
        require(amount != 0, "Amount can not be 0");
        CheddaXP(registry.cheddaXP()).mint(amount, user);
        address epoch = currentEpoch();
        if (epoch != address(0)) {
            CheddaCampaign(epoch).addPoints(amount, user);
        }

        emit RewardsIssued(action, amount, user);
    }

    /// @notice Slashes user rewards for bad behaviour. For example, this occurs when a users review is downvoted
    /// multiple times indicating possible spam or otherwise bad review.
    /// @dev Can only be called from MarketExplorer or DappstoreExplorer
    /// @param user Address of user that performed action.
    function slashRewards(address user) public onlyExplorer() {
        uint256 amount = pointsPerAction[Actions.Downvote];
       CheddaXP(registry.cheddaXP()).slash(amount, user);
       address epoch = currentEpoch();
       if (epoch != address(0)) {
           CheddaCampaign(epoch).slashPoints(amount, user);
       }
        
       emit RewardsSlashed(amount, user);
    }

    /// @notice Creates a new epoch
    /// @dev Explain to a developer any extra details
    /// @param start must be > block.timestamp. Must be after all existing epochs
    /// @param duration must be >= 1 days and <= 366 days
    function createCampaign(
        string calldata name, 
        uint256 start, 
        uint256 duration, 
        address verificationContract,
        address distributionContract) public onlyOwner() {
        require(start > block.timestamp, "CR: Start must be future");
        require(duration >= 1 days && duration <= 366 days, "CR: Invalid duration");
        require(!_epochOverlaps(start), "CR: Overlap found");
        require(_startsAfterAllEpochs(start), "CR: Must be after epochs");

        uint256 end = start + duration;
        CheddaCampaign epoch = new CheddaCampaign(
            name, 
            start, 
            end, 
            boardSize, 
            verificationContract, 
            distributionContract
        );
        epochs.push(address(epoch));
    }

    /// @notice Claims a users prize for the given epoch
    /// @dev Epoch must have ended. Reverts if user is not eligible to claim prize in epoch.
    /// @param epochIndex The poch to claim prize for. Must be > 0 and < epochs.length
    function claimPrize(uint256 epochIndex) public {
        require(epochIndex < epochs.length, "CR: Invalid index");
        CheddaCampaign epoch = CheddaCampaign(epochs[epochIndex]);
        address caller = _msgSender();
        require(epoch.hasEnded(), "CR: Epoch has not ended");
        int position = epoch.position(caller);
        require(position >= 0, "CR: No prize");
        CheddaNFT.Rank nftRank = rank(uint256(position));
        CheddaNFT nft = CheddaNFT(registry.cheddaNFT());
        if (!nft.canGraduateToRank(caller, uint256(nftRank))) {
            nftRank = CheddaNFT.Rank(nft.attainableRank(caller));
        }
        if (nftRank != CheddaNFT.Rank.None && !epoch.hasClaimedPrize(caller)) {
            epoch.claimPrize(caller);
            nft.mint(caller, uint256(nftRank), 1, "");
        } else {
            revert("CR: No Prize");
        }
    }

    function currentEpoch() public view returns (address) {
        for (uint256 i = 0; i < epochs.length; i++) {
            CheddaCampaign epoch = CheddaCampaign(epochs[i]);
            if (epoch.isCurrent()) {
                return epochs[i];
            }
        }
        return address(0);
    }

    function lastEpoch() public view returns (address) {
        if (epochs.length == 0) {
            return address(0);
        }

        for (uint256 i = epochs.length - 1; i >= 0; i--) {
            CheddaCampaign epoch = CheddaCampaign(epochs[i]);
            if (epoch.end() < block.timestamp) {
                return epochs[i];
            }
        }
        return address(0);
    }

    function nextEpoch() public view returns (address) {
        for (uint256 i = 0; i < epochs.length; i++) {
            CheddaCampaign epoch = CheddaCampaign(epochs[i]);
            if (epoch.start() > block.timestamp) {
                return epochs[i];
            }
        }
        return address(0);
    }

    function _startsAfterAllEpochs(uint256 start) internal view returns (bool) {
        for (uint256 i = 0; i < epochs.length; i++) {
            CheddaCampaign epoch = CheddaCampaign(epochs[i]);
            if (start <= epoch.start() || start <= epoch.end()) {
                return false;
            }
        }
        return true;
    }

    function _epochOverlaps(uint256 start) internal view returns (bool) {
        for (uint256 i = 0; i < epochs.length; i++) {
            CheddaCampaign epoch = CheddaCampaign(epochs[i]);     
            if (start >= epoch.start() && start <= epoch.end()) {
                return true;
            }
        }
        return false;
    }

    function rank(uint256 position) public pure returns (CheddaNFT.Rank) {
        if (position == RANK_BOSS) {
            return CheddaNFT.Rank.Boss;
        } else if (position < RANK_UNDERBOSS) {
            return CheddaNFT.Rank.Underboss;
        } else if (position < RANK_CONSIGLIERE) {
            return CheddaNFT.Rank.Consigliere;
        } else if (position < RANK_CAPOREGIME) {
            return CheddaNFT.Rank.Consigliere;
        } else if (position < RANK_SOLDIER) {
            return CheddaNFT.Rank.Consigliere;
        } else if (position < RANK_ASSOCIATE) {
            return CheddaNFT.Rank.Consigliere;
        } 
        return CheddaNFT.Rank.None;
    }

}
