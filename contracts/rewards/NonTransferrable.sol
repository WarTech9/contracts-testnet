//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface INonTransferrable {
  
  function name() external view returns (bytes32);
  function symbol() external view returns (string memory);
}