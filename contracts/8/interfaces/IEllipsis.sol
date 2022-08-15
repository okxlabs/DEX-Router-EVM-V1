// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IEllipsis {
    // For two crypto pools
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external payable ;

    function exchange_underlying(
        int128 i, 
        int128 j, 
        uint256 dx, 
        uint256 min_dy
    ) external;

}
