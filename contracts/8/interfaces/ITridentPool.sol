// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface ITridentPool {
    function swap(
        bytes calldata data
    ) external returns (uint256);
}
