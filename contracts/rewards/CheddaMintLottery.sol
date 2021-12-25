//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../common/CheddaAddressRegistry.sol";
import "../market/MarketNFT.sol";

contract CheddaMintLottery {

    ICheddaAddressRegistry public registry;

    // check if user is holder of Chedda NFT
    modifier isCheddaGangMember() {
        _;
    }

    function enter() public isCheddaGangMember() {

    }
}