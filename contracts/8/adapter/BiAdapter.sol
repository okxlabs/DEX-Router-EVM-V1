// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IBiswapPair.sol";
import "../interfaces/IERC20.sol";

contract BiAdapter is IAdapter {
    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory
    ) external override {
        address baseToken = IBiswapPair(pool).token0();
        (uint256 reserveIn, uint256 reserveOut, ) = IBiswapPair(pool)
            .getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "BiswapAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0 = IERC20(baseToken).balanceOf(pool);
        uint256 sellBaseAmount = balance0 - reserveIn;

        uint256 sellBaseAmountWithFee = sellBaseAmount *
            (1000 - IBiswapPair(pool).swapFee());
        uint256 numerator = sellBaseAmountWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + sellBaseAmountWithFee;
        uint256 receiveQuoteAmount = numerator / denominator;
        IBiswapPair(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory
    ) external override {
        address quoteToken = IBiswapPair(pool).token1();
        (uint256 reserveOut, uint256 reserveIn, ) = IBiswapPair(pool)
            .getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "BiswapAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance1 = IERC20(quoteToken).balanceOf(pool);
        uint256 sellQuoteAmount = balance1 - reserveIn;

        uint256 sellQuoteAmountWithFee = sellQuoteAmount *
            (1000 - IBiswapPair(pool).swapFee());
        uint256 numerator = sellQuoteAmountWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + sellQuoteAmountWithFee;
        uint256 receiveBaseAmount = numerator / denominator;
        IBiswapPair(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }
}
