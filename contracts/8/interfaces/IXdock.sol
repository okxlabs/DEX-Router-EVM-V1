/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

interface IXdock {

    function buyExactIn(
        address token,
        uint256 minTokenAmountOut
    ) external payable;

    function sellExactIn(
        address token,
        address trader, // Selling token source address(tx.origin)
        uint256 exactTokenAmountIn,
        uint256 minEthAmountOut
    ) external;
}
