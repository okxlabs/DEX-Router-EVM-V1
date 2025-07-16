// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IChronosPair.sol";
import "../interfaces/IERC20.sol";

/// @title ChronosAdapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract ChronosAdapter is IAdapter {
    // fromToken == token0
    function sellBase(
        address receipt,
        address pair,
        bytes memory
    ) external override {
        address baseToken = IChronosPair(pair).token0();
        (uint256 reserveIn, uint256 reserveOut, ) = IChronosPair(pair).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "ChronosAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0 = IERC20(baseToken).balanceOf(pair);
        uint256 sellBaseAmount = balance0 - reserveIn;

        uint256 amountOut = IChronosPair(pair).getAmountOut(
            sellBaseAmount,
            baseToken
        );
        IChronosPair(pair).swap(0, amountOut, receipt, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address receipt,
        address pair,
        bytes memory
    ) external override {
        address quoteToken = IChronosPair(pair).token1();
        (uint256 reserveOut, uint256 reserveIn, ) = IChronosPair(pair).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "ChronosAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance1 = IERC20(quoteToken).balanceOf(pair);
        uint256 sellQuoteAmount = balance1 - reserveIn;

        uint256 amountOut = IChronosPair(pair).getAmountOut(
            sellQuoteAmount,
            quoteToken
        );
        IChronosPair(pair).swap(amountOut, 0, receipt, new bytes(0));
    }
}
