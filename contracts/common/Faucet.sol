//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
}

/// @title Faucet
/// @notice Faucet for slowly emitting tokens deposited. Used for testing.
/// @dev Explain to a developer any extra details
contract Faucet {

    uint256 public dripAmount = 1_000 * 10 ** 18;

    event TokensReceived(address indexed token, address indexed from, uint256 amount);
    event TokensSent(address indexed token, address indexed to, uint256 amount);

    /// @notice The last time an address was dripped tokens.
    /// @dev token address => user address => last dripped time
    mapping (address => mapping (address => uint256)) public lastDripped;

    /// @notice Token balances
    mapping (address => uint256) private balances;

    /// @notice The minimum period an account must wait to be refilled.
    uint256 public minDripTimeout = 1 days;
    
    /// @notice Fill the faucet
    /// @dev `token` must be ERC-20 and `amount` must be approved by the caller.
    /// @param token Address token of faucet to fill.
    /// @param amount Amount to refill with.
    /// param amount Amount to fill the token with.
    function fill(address token, uint256 amount) public {
        ERC20(token).transferFrom(msg.sender, address(this), amount);
        
        emit TokensReceived(token, msg.sender, amount);
    }

    /// @notice Returns  much of `token` currently held by this smart contract.
    /// @dev Explain to a developer any extra details
    /// @param token Address to token to return balanc for.
    /// @return return balance of `token` in this address
    function balanceOf(address token) public view returns (uint256) {
        return balances[token];
    }

    /// @dev Anyone can fill the faucet.
    /// @param token token to drip
    function drip(address token) public {
        address recipient = msg.sender;

        require(block.timestamp > lastDripped[token][recipient] + minDripTimeout, "CHFaucet: Must wait");
        lastDripped[token][recipient] = block.timestamp;
        ERC20(token).transfer(recipient, dripAmount);

        emit TokensSent(token, recipient, dripAmount);
    }

}
