// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IKyber.sol";
import "../interfaces/IERC20.sol";

/// @title KyberAdapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract KyberAdapter is IAdapter {
    
    uint internal constant PRECISION = 10**18; // fee of base

    // fromToken == token0
    function sellBase(address to, address pool, bytes memory) external override {
        IERC20 baseToken = IKyber(pool).token0();
        (uint reserveIn, uint reserveOut,uint vReserveIn,uint vReserveOut,uint feeInPrecision) = IKyber(pool).getTradeInfo();
        require(reserveIn > 0 && reserveOut > 0, "KyberAdapter: INSUFFICIENT_LIQUIDITY");

        // if is amp pool, vReserveIn = reserveIn, vReserveOut = reserveOut

        uint balance0 = baseToken.balanceOf(pool);

        uint sellBaseAmountWithFee = (balance0 - reserveIn) * (PRECISION - feeInPrecision);
        uint receiveQuoteAmount = sellBaseAmountWithFee * vReserveOut / (vReserveIn * PRECISION + sellBaseAmountWithFee);
        
        IKyber(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(address to, address pool, bytes memory) external override {
        IERC20 quoteToken = IKyber(pool).token1();
        (uint reserveOut, uint reserveIn,uint vReserveOut,uint vReserveIn,uint feeInPrecision) = IKyber(pool).getTradeInfo();
        require(reserveIn > 0 && reserveOut > 0, "KyberAdapter: INSUFFICIENT_LIQUIDITY");
        
        uint balance1 = quoteToken.balanceOf(pool);
    
        uint sellQuoteAmountWithFee = (balance1 - reserveIn) * (PRECISION - feeInPrecision);
        uint receiveBaseAmount = sellQuoteAmountWithFee * vReserveOut / (vReserveIn * PRECISION + sellQuoteAmountWithFee);

        IKyber(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }
}