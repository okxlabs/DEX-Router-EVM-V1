// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IUni.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

/// @title UniAdapterForRebaseToken
/// @notice Adapter for handling swaps with rebase tokens on Uni pools.
contract UniAdapterForRebaseToken is IAdapter {
    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory
    ) external override {
        IUni(pool).sync();
        address baseToken = IUni(pool).token0();
        (uint256 reserveIn, uint256 reserveOut, ) = IUni(pool).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 amountIn = IERC20(baseToken).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(baseToken), pool, amountIn);

        uint256 balance0 = IERC20(baseToken).balanceOf(pool);
        uint256 sellBaseAmount = balance0 - reserveIn;

        uint256 receiveQuoteAmount;
        assembly {
            let sellAmountWithFee := mul(sellBaseAmount, 997)
            let numerator := mul(sellAmountWithFee, reserveOut)
            let denominator := add(mul(reserveIn, 1000), sellAmountWithFee)
            receiveQuoteAmount := div(numerator, denominator)
        }

        IUni(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory
    ) external override {
        IUni(pool).sync();
        address quoteToken = IUni(pool).token1();
        (uint256 reserveOut, uint256 reserveIn, ) = IUni(pool).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 amountIn = IERC20(quoteToken).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(quoteToken), pool, amountIn);

        uint256 balance1 = IERC20(quoteToken).balanceOf(pool);
        uint256 sellQuoteAmount = balance1 - reserveIn;

        uint256 receiveBaseAmount;
        assembly {
            let sellAmountWithFee := mul(sellQuoteAmount, 997)
            let numerator := mul(sellAmountWithFee, reserveOut)
            let denominator := add(mul(reserveIn, 1000), sellAmountWithFee)
            receiveBaseAmount := div(numerator, denominator)
        }

        IUni(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }
}
