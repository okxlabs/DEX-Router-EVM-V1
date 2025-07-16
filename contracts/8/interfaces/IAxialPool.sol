// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAxialPool {
    // the pool like curve pool

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

}

