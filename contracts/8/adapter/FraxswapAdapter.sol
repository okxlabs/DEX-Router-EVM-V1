// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IFraxswap.sol";
import "hardhat/console.sol";

/// @title FraxswapAdapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract FraxswapAdapter is IAdapter {
    // fromToken == token0
    
    function sellBase(
        address to,
        address pool,
        bytes memory
    ) external override {
        address baseToken = IFraxswap(pool).token0();
        (uint256 reserveIn, uint256 reserveOut, ) = IFraxswap(pool).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "FraxswapAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0 = IERC20(baseToken).balanceOf(pool);
        uint256 sellBaseAmount = balance0 - reserveIn;
        uint256 sellBaseAmountWithFee = sellBaseAmount * IFraxswap(pool).fee();
        uint256 numerator = sellBaseAmountWithFee * reserveOut;
        uint256 denominator = reserveIn * 10000 + sellBaseAmountWithFee;
        uint256 receiveQuoteAmount = numerator / denominator;
        IFraxswap(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory
    ) external override {
        address quoteToken = IFraxswap(pool).token1();
        (uint256 reserveOut, uint256 reserveIn, ) = IFraxswap(pool).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "FraxswapAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance1 = IERC20(quoteToken).balanceOf(pool);
        uint256 sellQuoteAmount = balance1 - reserveIn;
        uint256 receiveBaseAmount = IFraxswap(pool).getAmountOut(sellQuoteAmount, quoteToken);
        
        // ==== DEBUG ====
        console.log(sellQuoteAmount);
        console.log(quoteToken);
        console.log(receiveBaseAmount);

        address baseToken = IFraxswap(pool).token0();
        uint256 balance2 = IERC20(quoteToken).balanceOf(pool);
        console.log(baseToken);
        console.log(balance2);

        IFraxswap(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }
}
