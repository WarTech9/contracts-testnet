//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;


interface INonTransferrable {
  
  function name() external view returns (bytes32);
  function symbol() external view returns (string memory);
}