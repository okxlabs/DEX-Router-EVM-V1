// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";

interface IUni {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract BakeryAdapter is IAdapter {
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
            "BakeryAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0 = IERC20(baseToken).balanceOf(pool);
        uint256 sellBaseAmount = balance0 - reserveIn;

        uint256 sellBaseAmountWithFee = sellBaseAmount * 997;
        uint256 numerator = sellBaseAmountWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + sellBaseAmountWithFee;
        uint256 receiveQuoteAmount = numerator / denominator;
        IUni(pool).swap(0, receiveQuoteAmount, to);
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
            "BakeryAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance1 = IERC20(quoteToken).balanceOf(pool);
        uint256 sellQuoteAmount = balance1 - reserveIn;

        uint256 sellQuoteAmountWithFee = sellQuoteAmount * 997;
        uint256 numerator = sellQuoteAmountWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + sellQuoteAmountWithFee;
        uint256 receiveBaseAmount = numerator / denominator;
        IUni(pool).swap(receiveBaseAmount, 0, to);
    }
}
