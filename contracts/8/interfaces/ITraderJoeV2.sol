// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILBPair {
    function swap(bool sentTokenY, address to) external returns (uint256 amountXOut, uint256 amountYOut);
}
