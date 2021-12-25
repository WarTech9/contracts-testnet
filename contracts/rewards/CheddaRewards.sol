//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/CheddaAddressRegistry.sol";
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

enum Rank {
    None,
    Associate,
    Soldier,
    Capo,
    Consigliere,
    Underboss,
    Boss,
    Godfather
}

interface ICheddaRewards {
   function issueRewards(Actions action, address user) external;
}

contract CheddaRewards is Ownable, ICheddaRewards {

    // Rewards issued in epoch
    struct UserRewards {
        address user;
        uint256 points;
        Rank rank;
    }

    struct Account {
        uint256 entered;
        uint256 earned;
    }

    struct Epoch {
        uint256 start;
        uint256 end;
        mapping (address => Account) accounts;
        
    }

    event RewardsIssued(Actions indexed a, uint256 indexed amount, address indexed user);
    event RewardsSlashed(uint256 amount, address indexed user);

    CheddaAddressRegistry public registry;

    mapping(Actions => uint256) public pointsPerAction;
    mapping(address => uint256) public pointsPerUser;

    // address => bool indicating if this user is currently on the leaderboard.
    mapping(address => bool) public userOnLeaderboard;

    // list of addresses on the leaderboard
    // this list is stored unsorted
    address[] public board;

    uint8 public BOARD_LENGTH = 100;
    uint256 public minimumPointsForReward = 0;

    uint256 public POINTS_PER_DOWNVOTE = 1;
    uint256 public POINTS_PER_UPVOTE = 1;
    uint256 public POINTS_PER_LIKE = 10;
    uint256 public POINTS_PER_DISLIKE = 10;
    uint256 public POINTS_PER_RATE = 10;
    uint256 public POINTS_PER_REVIEW = 30;
    uint256 public POINTS_PER_VOTE = 50;
    uint256 public pointsPerOther = 1;

    uint256 public constant RANK_GODFATHER = 0;
    uint256 public constant RANK_BOSS = 0;
    uint256 public constant RANK_UNDERBOSS = 1;
    uint256 public constant RANK_CONSIGLIERE = 5;
    uint256 public constant RANK_CAPOREGIME = 10;
    uint256 public constant RANK_SOLDIER = 20;
    uint256 public constant RANK_ASSOCIATE = 100;

    uint8 public constant MAX_BOARD_LENGTH = 100;
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

    function leaderboard() external view returns(UserRewards[] memory) {
        // return leaderboard
        address[] memory sortedAddresses = sortAddresses(board);
        UserRewards[] memory rewards = new UserRewards[](sortedAddresses.length);
        for (uint256 i = 0; i < sortedAddresses.length; i++) {
            rewards[i] = UserRewards(
                sortedAddresses[i], 
                pointsPerUser[sortedAddresses[i]],
                rank(i)
                );
        }
        return rewards;
    }
    
    function setRewards(Actions action, uint256 points) public onlyOwner {
        require(points != 0, "Points can not be 0");
        pointsPerAction[action] = points;
    }

    function claimPrize() public {
        
    }

    function rank(uint256 position) public pure returns (Rank) {
        if (position < RANK_UNDERBOSS) {
            return Rank.Underboss;
        } else if (position < RANK_CONSIGLIERE) {
            return Rank.Consigliere;
        } else if (position < RANK_CAPOREGIME) {
            return Rank.Consigliere;
        } else if (position < RANK_SOLDIER) {
            return Rank.Consigliere;
        } else if (position < RANK_ASSOCIATE) {
            return Rank.Consigliere;
        } 
        return Rank.None;
    }

    function issueRewards(Actions action, address user)
        public
        override
    {
        require(user != address(0), "Address can not be 0");
        uint256 amount = pointsPerAction[action];
        require(amount != 0, "Amount can not be 0");
        pointsPerUser[user] += amount;
        CheddaXP(registry.cheddaXP()).mint(amount, user);
        _updateBoard(user);

        emit RewardsIssued(action, amount, user);
    }

    function _slashRewards(address user) internal {
        uint256 amount = pointsPerAction[Actions.Downvote];
       CheddaXP(registry.cheddaXP()).slash(amount, user);
        
       emit RewardsSlashed(amount, user);
    }

    // Leaderboard
    // Leaderboard implementation resultsin O(1) inserts as reshuffling board is not 
    // required for each insert (highly costly operation). The drawback is O(n) reads
    // which is not born by the user since read operations are free. A caching mechanism
    // can be implementd to rectify this drawback.
    function _updateBoard(address user) internal {
        if (_userExists(user)) {
            return;
        }

        // board is not full, can just add
        if (board.length < MAX_BOARD_LENGTH) {
            board.push(user);
            userOnLeaderboard[user] = true;

        // Board is full, check if current user should be added to board
        // 1. find current minimum points
        // 2. compare with incoming value
        // 3. If lower, update board accordingly
        } else if (pointsPerUser[user] > minimumPointsForReward) {
            uint8 minIndex = _findMinIndex();
            uint256 pointsForMinUser = pointsPerUser[board[minIndex]]; 
            if (pointsForMinUser < pointsPerUser[user]) {
                address userToRemove = board[minIndex];
                userOnLeaderboard[userToRemove] = false;
                userOnLeaderboard[user] = true;
                board[minIndex] = user;
                minimumPointsForReward = pointsPerUser[user];
            }
        }
    }

    function _userExists(address user) internal view returns (bool) {
        return userOnLeaderboard[user];
    }

    function _findMinIndex() internal view returns (uint8) {
        uint256 min = pointsPerUser[board[0]];
        uint8 minIndex = 0;
        for (uint8 i = 0; i < board.length; i++) {
            if (pointsPerUser[board[i]] < min) {
                min = pointsPerUser[board[i]];
                minIndex = i;
            }
        }
        return minIndex;
    }

    function sort(uint[] memory data) internal view returns(uint[] memory) {
        if (data.length > 0) {
            quickSort(data, int(0), int(data.length - 1));
        }
        return data;
    }

    function sortRewards(UserRewards[] memory data) internal view returns(UserRewards[] memory) {
        if (data.length > 0) {
            quickSortRewards(data, int(0), int(data.length - 1));
        }
       return data;
    }

    function sortAddresses(address[] memory data) internal view returns(address[] memory) {
        if (data.length > 0) {
            quickSortAddresses(data, int(0), int(data.length - 1));
        }
        return data;
    }
    
    function quickSort(uint[] memory arr, int left, int right) internal view {
        int i = left;
        int j = right;
        if(i>=j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    function quickSortRewards(UserRewards[] memory arr, int left, int right) internal view {
        int i = left;
        int j = right;
        if(i>=j) return;
        uint pivot = arr[uint(left + (right - left) / 2)].points;
        while (i <= j) {
            while (arr[uint(i)].points < pivot) i++;
            while (pivot < arr[uint(j)].points) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortRewards(arr, left, j);
        if (i < right)
            quickSortRewards(arr, i, right);
    }

    function quickSortAddresses(address[] memory arr, int left, int right) internal view {
        int i = left;
        int j = right;
        if(i>=j) return;
        uint pivot = pointsPerUser[arr[uint(left + (right - left) / 2)]];
        while (i <= j) {
            while (pointsPerUser[arr[uint(i)]] > pivot) i++;
            while (pivot > pointsPerUser[arr[uint(j)]]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortAddresses(arr, left, j);
        if (i < right)
            quickSortAddresses(arr, i, right);
    }
}
