//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMintLock {
    function canMint() external view returns (bool);
    function recordMint() external returns (bool);
}

contract TimedMintlock is Ownable, IMintLock {

    uint256 public cooldown;
    mapping(address => uint256) public timeouts;

    constructor(uint256 _cooldown) Ownable() {
        cooldown = _cooldown;
    }

    function setCooldown(uint256 _newCooldown) external onlyOwner() {
        cooldown = _newCooldown;
    }
    
    function canMint() external view override returns (bool) {
        uint256 timeout = timeouts[_msgSender()];
        return timeout == 0 || block.timestamp > timeout;
    }

    function recordMint() external override returns (bool) {
        timeouts[_msgSender()] = block.timestamp + cooldown;
        return true;
    }
}

contract CheddaTimedMintLock is TimedMintlock {

    constructor() TimedMintlock(1 days) {}
}
