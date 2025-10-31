// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

interface IDssLitePsm {
    function sellGem(
        address usr,
        uint256 gemAmt
    ) external returns (uint256);

    function buyGem(
        address usr,
        uint256 gemAmt
    ) external returns (uint256);
}
