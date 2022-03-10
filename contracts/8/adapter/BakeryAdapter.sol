// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";

interface IUni {
    function swap(uint amount0Out, uint amount1Out, address to) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract BakeryAdapter is IAdapter {
    // fromToken == token0
    function sellBase(address to, address pool, bytes memory) external override {
        address baseToken = IUni(pool).token0();
        (uint reserveIn, uint reserveOut,) = IUni(pool).getReserves();
        require(reserveIn > 0 && reserveOut > 0, 'BakeryAdapter: INSUFFICIENT_LIQUIDITY');

        uint balance0 = IERC20(baseToken).balanceOf(pool);
        uint sellBaseAmount = balance0 - reserveIn;
        
        uint sellBaseAmountWithFee = sellBaseAmount * 997;
        uint numerator = sellBaseAmountWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + sellBaseAmountWithFee;
        uint receiveQuoteAmount = numerator / denominator;
        IUni(pool).swap(0, receiveQuoteAmount, to);
    }

    // fromToken == token1
    function sellQuote(address to, address pool, bytes memory) external override {
        address quoteToken = IUni(pool).token1();
        (uint reserveOut, uint reserveIn,) = IUni(pool).getReserves();
        require(reserveIn > 0 && reserveOut > 0, 'BakeryAdapter: INSUFFICIENT_LIQUIDITY');

        uint balance1 = IERC20(quoteToken).balanceOf(pool);
        uint sellQuoteAmount = balance1 - reserveIn;

        uint sellQuoteAmountWithFee = sellQuoteAmount * 997;
        uint numerator = sellQuoteAmountWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + sellQuoteAmountWithFee;
        uint receiveBaseAmount = numerator / denominator;
        IUni(pool).swap(receiveBaseAmount, 0, to);
    }
}