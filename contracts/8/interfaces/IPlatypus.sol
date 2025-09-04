// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

interface IPlatypus {
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);
}
