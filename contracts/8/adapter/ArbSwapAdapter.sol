// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IArbSwapPair.sol";
import "../interfaces/IERC20.sol";

/// @title ArbSwapAdapter
contract ArbSwapAdapter is IAdapter {
    // fromToken == token0
    function sellBase(
        address receipt,
        address pair,
        bytes memory
    ) external override {
        address baseToken = IArbSwapPair(pair).token0();
        (uint112 reserveIn, uint112 reserveOut, ) = IArbSwapPair(pair).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "ArbSwapAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 baseBalance = IERC20(baseToken).balanceOf(pair);
        uint256 amountIn = baseBalance - reserveIn;
        require(amountIn > 0, "ArbSwapAdapter: no base balance");

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        uint256 amountOut = numerator / denominator;
        IArbSwapPair(pair).swap(0, amountOut, receipt, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address receipt,
        address pair,
        bytes memory
    ) external override {
        address quoteToken = IArbSwapPair(pair).token1();
        (uint256 reserveOut, uint256 reserveIn, ) = IArbSwapPair(pair).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "ArbSwapAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 quoteBalance = IERC20(quoteToken).balanceOf(pair);
        uint256 amountIn = quoteBalance - reserveIn;
        require(amountIn > 0, "ArbSwapAdapter: no quote balance");

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        uint256 amountOut = numerator / denominator;
        IArbSwapPair(pair).swap(amountOut, 0, receipt, new bytes(0));
    }
}
