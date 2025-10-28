// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IGmxVault {
    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);
}
