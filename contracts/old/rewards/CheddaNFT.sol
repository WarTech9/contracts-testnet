//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../common/CheddaAddressRegistry.sol";

contract CheddaNFT is ERC1155, Ownable {

    event RegistryUpdated(address indexed by, address indexed newAddress);
    event Minted(address indexed to, uint256 indexed id, uint256 amount);

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

    ICheddaAddressRegistry public registry;

    modifier onlyRewards() {
        require(
            _msgSender() == registry.rewards(),
            "Not allowed: Only Rewards"
        );
        _;
    }

    constructor(string memory uri_) ERC1155(uri_) {
    }

    function updateRegistry(address registryAddress) external onlyOwner {
        registry = ICheddaAddressRegistry(registryAddress);
        emit RegistryUpdated(_msgSender(), registryAddress);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual onlyRewards() {
        require(_isValidRank(id), "Invalid id");
        require(canGraduateToRank(to, id), "Needs lower rank");
        _mint(to, id, amount, data);

        emit Minted(to, id, amount);
    }

    function highestRank(address user) public view returns (uint256) {
        for (uint256 i = uint256(Rank.Godfather); i > 0 ; i--) {
            if (balanceOf(user, i) > 0) {
               return i; 
            } 
        }
        return 0;
    }

    function attainableRank(address user) public view returns (uint256) {
        for (uint i = uint(Rank.Boss); i > 0; i--) {
            if (balanceOf(user, i) > 0) {
                return i + 1;
            }
        }
        return 1;
    }

    function canGraduateToRank(address user, uint256 rank) public view returns (bool) {
        if (rank == 0 || rank == 1) {
            return true;
        }
        return balanceOf(user, rank - 1) > 0;
    }

    function _isValidRank(uint256 rankValue) private pure returns (bool) {
        Rank(rankValue); // with revert if rank is invalid
        return true;
    }

}
