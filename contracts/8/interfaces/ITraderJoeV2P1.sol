// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Liquidity Book Pair Interface
/// @author Trader Joe
/// @notice Required interface of LBPair contract
interface ILBPair {
    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);
}
