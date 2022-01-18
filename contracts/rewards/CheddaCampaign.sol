//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./verification/ICheddaVerifier.sol";
import "./distribution/ICheddaDistribution.sol";

struct AddressWithPoints {
    address user;
    uint256 points;
}

/// @title CheddaCampaign
/// @notice A bounty is a period of time where users can compete for prizes.
/// @dev Explain to a developer any extra details
contract CheddaCampaign is Ownable {

    event AddedPoints(address indexed user, uint256 points);
    event SlashedPoints(address indexed user, uint256 points);

    using Address for address;

    enum PrizeType {
        erc20Drop,
        erc721Drop,
        erc1155Drop
    }

    enum ShareModel {
        evenDistribution,
        pieDistribution,
        lottery
    }

    string public name;
    uint256 public start;
    uint256 public end;
    /// @notice unsorted list of addresses currently on the leaderboard
    /// @dev Explain to a developer any extra details
    address[] public leaderboard;
    uint32 public boardSize;
    uint256 public minimumPointsForReward = 0;
    mapping(address => bool) public hasClaimedPrize;
    mapping(address => uint256) public pointsPerUser;

    // address => bool indicating if this user is currently on the leaderboard.
    mapping(address => bool) public userOnLeaderboard;
    ICheddaVerifier public verificationContract;
    ICheddaDistribution public distribtionContract;

    /// @notice Creates a new campaign
    /// @param _name The name of the campaign
    /// @param _start The start time in seconds
    /// @param _end The end time of campaign
    /// @param _boardSize The size of the leaderboard. This is the number of users to keep track of.
    /// For example, if there are 1000 users participating in the campaign, but boardSize is 100, 
    /// the leaderboard only keeps track of the top 100 users.
    constructor(string memory _name, uint256 _start, uint256 _end, uint32 _boardSize) {
        // require(start > block.timestamp, "Campaign: Invalid start");
        // require(end > start, "Campaign: Invalid end");
        require(_boardSize > 0 && boardSize <= 1000, "Invalid boardSize");
        // require(_verification != address(0) && _distribution != address(0) &&
        // _verification.isContract() && _distribution.isContract(),
        // "Campaign: Invalid address"
        // );

        name = _name;
        start = _start;
        end = _end;
        boardSize = _boardSize;
    }

    function addPoints(uint256 points, address user) public onlyOwner() {
        require(user != address(0), "Campaign: Invalid Address");
        require(points != 0, "Campaign: Invalid Points");

        pointsPerUser[user] += points;
        _updateBoard(user);

        emit AddedPoints(user, points);
    }

    function slashPoints(uint256 points, address user) public onlyOwner() {
        require(user != address(0), "Campaign: Invalid Address");
        require(points != 0, "Campaign: Invalid Points");

        uint256 pointsToSlash = points;
        if (pointsToSlash > pointsPerUser[user]) {
            pointsToSlash = pointsPerUser[user];
        }
        pointsPerUser[user] -= pointsToSlash;
        _updateBoard(user);
        
        emit SlashedPoints(user, points);
    }

    function claimPrize(address user) public onlyOwner() {
        require(!hasClaimedPrize[user], "Campaign: Already claimed");
        hasClaimedPrize[user] = true;
    }

    function hasStarted() public view returns (bool) {
        return start < block.timestamp;
    }

    function hasEnded() public view returns (bool) {
        return end > block.timestamp;
    }

    function isCurrent() public view returns (bool) {
        return hasStarted() && !hasEnded();
    }

    function position(address user) public view returns (int256) {
        address[] memory sortedAddresses = _sortAddresses(leaderboard);
        for (uint256 i = 0; i < sortedAddresses.length; i++) {
            if (user == sortedAddresses[i]) {
                return int256(i);
            }
        }
        return -1;
    }

    function sortedBoard() external view returns(AddressWithPoints[] memory) {
        address[] memory sortedAddresses = _sortAddresses(leaderboard);
        AddressWithPoints[] memory addresses = new AddressWithPoints[](sortedAddresses.length);
        for (uint256 i = 0; i < sortedAddresses.length; i++) {
            addresses[i] = AddressWithPoints(
                sortedAddresses[i], 
                pointsPerUser[sortedAddresses[i]]
            );
        }
        return addresses;
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
        if (leaderboard.length < boardSize) {
            leaderboard.push(user);
            userOnLeaderboard[user] = true;

        // Board is full, check if current user should be added to board
        // 1. find current minimum points
        // 2. compare with incoming value
        // 3. If lower, update board accordingly
        } else if (pointsPerUser[user] > minimumPointsForReward) {
            uint8 minIndex = _findMinIndex();
            uint256 pointsForMinUser = pointsPerUser[leaderboard[minIndex]]; 
            if (pointsForMinUser < pointsPerUser[user]) {
                address userToRemove = leaderboard[minIndex];
                userOnLeaderboard[userToRemove] = false;
                userOnLeaderboard[user] = true;
                leaderboard[minIndex] = user;
                minimumPointsForReward = pointsPerUser[user];
            }
        }
    }

    function _userExists(address user) internal view returns (bool) {
        return userOnLeaderboard[user];
    }

    function _findMinIndex() internal view returns (uint8) {
        uint256 min = pointsPerUser[leaderboard[0]];
        uint8 minIndex = 0;
        for (uint8 i = 0; i < leaderboard.length; i++) {
            if (pointsPerUser[leaderboard[i]] < min) {
                min = pointsPerUser[leaderboard[i]];
                minIndex = i;
            }
        }
        return minIndex;
    }

    function _sortAddresses(address[] memory data) private view returns(address[] memory) {
        if (data.length > 0) {
            _quickSortAddresses(data, int(0), int(data.length - 1));
        }
        return data;
    }

    function _quickSortAddresses(address[] memory arr, int left, int right) private view {
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
            _quickSortAddresses(arr, left, j);
        if (i < right)
            _quickSortAddresses(arr, i, right);
    }
}
