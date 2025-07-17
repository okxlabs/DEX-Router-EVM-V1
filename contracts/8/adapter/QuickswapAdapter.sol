// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IQuick.sol";
import "../interfaces/IERC20.sol";

/// @title QuickswapAdapter 
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract QuickswapAdapter is IAdapter {
    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory
    ) external override {
        address baseToken = IQuick(pool).token0();
        (uint256 reserveIn, uint256 reserveOut, ) = IQuick(pool).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "QuickswapAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0 = IERC20(baseToken).balanceOf(pool);
        uint256 sellBaseAmount = balance0 - reserveIn;

        uint256 sellBaseAmountWithFee = sellBaseAmount * 997;
        uint256 numerator = sellBaseAmountWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + sellBaseAmountWithFee;
        uint256 receiveQuoteAmount = numerator / denominator;
        IQuick(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory
    ) external override {
        address quoteToken = IQuick(pool).token1();
        (uint256 reserveOut, uint256 reserveIn, ) = IQuick(pool).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "QuickswapAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance1 = IERC20(quoteToken).balanceOf(pool);
        uint256 sellQuoteAmount = balance1 - reserveIn;

        uint256 sellQuoteAmountWithFee = sellQuoteAmount * 997;
        uint256 numerator = sellQuoteAmountWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + sellQuoteAmountWithFee;
        uint256 receiveBaseAmount = numerator / denominator;
        IQuick(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }
}
