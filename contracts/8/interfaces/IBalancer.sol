// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IBalancer {

    function getCurrentTokens() external view returns (address[] memory tokens);

    function swapExactAmountIn(
        address tokenIn, 
        uint tokenAmountIn, 
        address tokenOut,  
        uint minAmountOut,  
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountIn, uint spotPriceAfter);

}