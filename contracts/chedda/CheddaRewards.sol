//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Chedda.sol";
import "../common/CheddaAddressRegistry.sol";

contract CheddaRewards is Context, Ownable {

    enum Actions {
        Like,
        Rate,
        Review,
        Vote
    }

    Chedda public chedda;
    CheddaAddressRegistry public registry;

    mapping (Actions => uint256) public pointsPerAction;

    uint256 constant public POINTS_PER_LIKE = 10;
    uint256 constant public POINTS_PER_RATE = 10;
    uint256 constant public POINTS_PER_REVIEW = 30;
    uint256 constant public POINTS_PER_VOTE = 50;

    modifier onlyExplorer() {
        require(_msgSender() == registry.dappstoreExplorer() || _msgSender() == registry.marketExplorer(),
        "Not allowed: Only Explorer");
        _;
    }

    constructor(address cheddaAddress) {
        chedda = Chedda(cheddaAddress);

        setRewards(Actions.Like, POINTS_PER_LIKE);
        setRewards(Actions.Rate, POINTS_PER_RATE);
        setRewards(Actions.Review, POINTS_PER_REVIEW);
        setRewards(Actions.Vote, POINTS_PER_VOTE);
    }

    function updateRegistry(address registryAddress) external onlyOwner() {
        registry = CheddaAddressRegistry(registryAddress);
    }

    function setRewards(Actions action, uint256 points) public onlyOwner() {
        require(points != 0, "Points can not be 0");
        pointsPerAction[action] = points;
    }

    function issueRewards(Actions action, address user) public onlyExplorer() {
        require(user != address(0), "Address can not be 0");
        uint256 _amount = pointsPerAction[action];
        require(_amount != 0, "Amount can not be 0");
        chedda.mint(_amount, user);
    }

}