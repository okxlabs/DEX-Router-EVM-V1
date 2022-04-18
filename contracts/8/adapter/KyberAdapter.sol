// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IKyber.sol";
import "../interfaces/IERC20.sol";

/// @title KyberAdapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract KyberAdapter is IAdapter {
    uint256 internal constant PRECISION = 10**18; // fee of base

    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory
    ) external override {
        IERC20 baseToken = IKyber(pool).token0();
        (
            uint256 reserveIn,
            uint256 reserveOut,
            uint256 vReserveIn,
            uint256 vReserveOut,
            uint256 feeInPrecision
        ) = IKyber(pool).getTradeInfo();
        require(
            reserveIn > 0 && reserveOut > 0,
            "KyberAdapter: INSUFFICIENT_LIQUIDITY"
        );

        // if is amp pool, vReserveIn = reserveIn, vReserveOut = reserveOut

        uint256 balance0 = baseToken.balanceOf(pool);

        uint256 sellBaseAmountWithFee = ((balance0 - reserveIn) *
            (PRECISION - feeInPrecision)) / PRECISION;
        uint256 receiveQuoteAmount = (sellBaseAmountWithFee * vReserveOut) /
            (vReserveIn + sellBaseAmountWithFee);

        IKyber(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory
    ) external override {
        IERC20 quoteToken = IKyber(pool).token1();
        (
            uint256 reserveOut,
            uint256 reserveIn,
            uint256 vReserveOut,
            uint256 vReserveIn,
            uint256 feeInPrecision
        ) = IKyber(pool).getTradeInfo();
        require(
            reserveIn > 0 && reserveOut > 0,
            "KyberAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance1 = quoteToken.balanceOf(pool);

        uint256 sellQuoteAmountWithFee = ((balance1 - reserveIn) *
            (PRECISION - feeInPrecision)) / PRECISION;
        uint256 receiveBaseAmount = (sellQuoteAmountWithFee * vReserveOut) /
            (vReserveIn + sellQuoteAmountWithFee);

        IKyber(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }
}
