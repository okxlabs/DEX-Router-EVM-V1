// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IUni.sol";
import "../interfaces/IERC20.sol";

contract PancakeAdapter is IAdapter {
    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory
    ) external override {
        address baseToken = IUni(pool).token0();
        (uint256 reserveIn, uint256 reserveOut, ) = IUni(pool).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "PancakeAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0 = IERC20(baseToken).balanceOf(pool);
        uint256 sellBaseAmount = balance0 - reserveIn;

        uint256 sellBaseAmountWithFee = sellBaseAmount * 9975;
        uint256 numerator = sellBaseAmountWithFee * reserveOut;
        uint256 denominator = reserveIn * 10000 + sellBaseAmountWithFee;
        uint256 receiveQuoteAmount = numerator / denominator;
        IUni(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory
    ) external override {
        address quoteToken = IUni(pool).token1();
        (uint256 reserveOut, uint256 reserveIn, ) = IUni(pool).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "PancakeAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance1 = IERC20(quoteToken).balanceOf(pool);
        uint256 sellQuoteAmount = balance1 - reserveIn;

        uint256 sellQuoteAmountWithFee = sellQuoteAmount * 9975;
        uint256 numerator = sellQuoteAmountWithFee * reserveOut;
        uint256 denominator = reserveIn * 10000 + sellQuoteAmountWithFee;
        uint256 receiveBaseAmount = numerator / denominator;
        IUni(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }
}
