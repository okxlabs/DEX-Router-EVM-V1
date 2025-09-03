// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExtsload {
    function extsload(bytes32 slot) external view returns (bytes32 value);

    function extsload(bytes32 startSlot, uint256 nSlots) external view returns (bytes32[] memory values);

    function extsload(bytes32[] calldata slots) external view returns (bytes32[] memory values);
}
