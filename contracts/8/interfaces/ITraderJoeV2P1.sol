// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILBPair {
    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);
}
