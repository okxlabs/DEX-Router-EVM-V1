// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

interface IPancakeStableSwapTwoPool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;
}
