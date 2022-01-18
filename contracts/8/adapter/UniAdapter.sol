// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IUni.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";

/// @title UniAdapter
/// @author Oker
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract UniAdapter is IAdapter {
    using SafeMath for uint;

    // fromToken == token0
    function sellBase(address to, address pool, bytes memory) external override {
        address baseToken = IUni(pool).token0();
        (uint reserveIn, uint reserveOut,) = IUni(pool).getReserves();
        require(reserveIn > 0 && reserveOut > 0, 'UniAdapter: INSUFFICIENT_LIQUIDITY');
        
        uint balance0 = IERC20(baseToken).balanceOf(pool);
        uint sellBaseAmount = balance0 - reserveIn;

        uint sellBaseAmountWithFee = sellBaseAmount.mul(997);
        uint numerator = sellBaseAmountWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(sellBaseAmountWithFee);
        uint receiveQuoteAmount = numerator / denominator;
        IUni(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(address to, address pool, bytes memory) external override {
        address quoteToken = IUni(pool).token1();
        (uint reserveOut, uint reserveIn,) = IUni(pool).getReserves();
        require(reserveIn > 0 && reserveOut > 0, 'UniAdapter: INSUFFICIENT_LIQUIDITY');
        
        uint balance1 = IERC20(quoteToken).balanceOf(pool);
        uint sellQuoteAmount = balance1 - reserveIn;
        
        uint sellQuoteAmountWithFee = sellQuoteAmount.mul(997);
        uint numerator = sellQuoteAmountWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(sellQuoteAmountWithFee);
        uint receiveBaseAmount = numerator / denominator;
        IUni(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }
}