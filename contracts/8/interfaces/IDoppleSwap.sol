// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IDoppleSwap {
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    )external returns (uint256);

    function getTokenIndex(address tokenAddress) external view returns (uint8); 
    
}
