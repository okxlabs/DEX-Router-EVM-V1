// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IArbDexPair.sol";
import "../interfaces/IERC20.sol";

/// @title ArbDexAdapter
contract ArbDexAdapter is IAdapter {
    // fromToken == token0
    function sellBase(
        address receipt,
        address pair,
        bytes memory
    ) external override {
        address baseToken = IArbDexPair(pair).token0();
        (uint112 reserveIn, uint112 reserveOut, ) = IArbDexPair(pair).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "ArbSwapAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 baseBalance = IERC20(baseToken).balanceOf(pair);
        uint256 amountIn = baseBalance - reserveIn;
        require(amountIn > 0, "ArbSwapAdapter: no base balance");

        uint256 swapfee = 25; // 0.25% swap fee

        uint256 amountInWithFee = amountIn * (10000 - swapfee);
        uint256 amountOut = (amountInWithFee * reserveOut) / (reserveIn * 10000 + amountInWithFee);
        IArbDexPair(pair).swap(0, amountOut, receipt, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address receipt,
        address pair,
        bytes memory
    ) external override {
        address quoteToken = IArbDexPair(pair).token1();
        (uint256 reserveOut, uint256 reserveIn, ) = IArbDexPair(pair).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "ArbSwapAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 quoteBalance = IERC20(quoteToken).balanceOf(pair);
        uint256 amountIn = quoteBalance - reserveIn;
        require(amountIn > 0, "ArbSwapAdapter: no quote balance");

        uint256 swapfee = 25; // 0.25% swap fee

        uint256 amountInWithFee = amountIn * (10000 - swapfee);
        uint256 amountOut = (amountInWithFee * reserveOut) / (reserveIn * 10000 + amountInWithFee);
        IArbDexPair(pair).swap(amountOut, 0, receipt, new bytes(0));
    }
}
