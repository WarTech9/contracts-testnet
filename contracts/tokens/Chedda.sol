//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import { ERC20 } from "./ERC20.sol";

interface IRebaseToken {
    function rebase() external;
}

contract Chedda is ERC20, IRebaseToken {

    event VaultSet(address indexed vault, address indexed by);
    event Rebased(address indexed vault, uint256 minted, uint256 totalSupply);
    
    uint256 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 400_000_000 * 10 ** DECIMALS;
    uint256 public constant APR_PRECISION = 100_000;

    /// @notice Vault for new token emission
    address public tokenVault;

    /// @notice New emission per second
    /// @dev TODO: Use emission rate (ratio of totalSupply)
    uint256 private _emissionPerSecond = 2 ** 4 * 10 ** DECIMALS;

    uint256 private _lastRebase;

    address private _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Chedda: Not owner");
        _;
    }
    
    /// @notice Construct a new Chedda token.
    /// @param account The initial account to grant all the tokens.
    constructor(address account)
    ERC20("Chedda", "CHEDDA", 18) {
        _owner = msg.sender;
        _lastRebase = block.timestamp;
        _mint(account, INITIAL_SUPPLY);
    }

    /// @notice Sets the vault for new token emission.
    /// @dev Can only be called once and by this contract owner.
    /// @param vault The token vault.
    function setVault(address vault) public onlyOwner {
        require(tokenVault == address(0), "Chedda: :Vault already inited");
        tokenVault = vault;
    }

    /// @notice Increases token supply.
    function rebase() public override {
        if (_lastRebase >= block.timestamp) {
            return;
        }

        uint256 amountToMint = (block.timestamp - _lastRebase) * _emissionPerSecond;
        require(amountToMint > 0, "Invalid timestamp");
        _lastRebase = block.timestamp;

        _mint(tokenVault, amountToMint);

        emit Rebased(tokenVault, amountToMint, totalSupply);
    }

    /// @notice Current APR
    function apr() public view returns (uint256) {
        return _emissionPerSecond * 365 days * APR_PRECISION / totalSupply;
    }
}
