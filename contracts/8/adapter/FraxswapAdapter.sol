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
    
    function getReservesWithTwamm(address pool) internal returns (uint256 reserve0, uint256 reserve1, uint256 twammReserve0, uint256 twammReserve1, uint256 fee) {
        IFraxswap(pool).executeVirtualOrders(block.timestamp);
        ( reserve0, reserve1, ,twammReserve0, twammReserve1,  fee) = IFraxswap(pool).getTwammReserves();
    }

    function _getAmountOut( address quoteToken, address pool, uint256 reserveIn, uint256 reserveOut, uint256 twammReserveIn, uint256 /*_twammReserveOut*/, uint256 fee) internal view returns (uint256 receiveBaseAmount)  {
        uint256 sellQuoteAmount = IERC20(quoteToken).balanceOf(pool) - reserveIn - twammReserveIn ;        
        uint256 sellQuoteAmountWithFee = sellQuoteAmount * (10000 - fee);
        uint256 numerator = sellQuoteAmountWithFee * reserveOut;
        uint256 denominator = reserveIn * 10000 + sellQuoteAmountWithFee;
        receiveBaseAmount = numerator / denominator;    
    }
    
    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory 
    ) external override {
        address baseToken = IFraxswap(pool).token0();
        (uint256 reserveIn, uint256 reserveOut, uint256 twammReserveIn, uint256 twammReserveOut, uint256 fee) = getReservesWithTwamm(pool);
        uint256 receiveQuoteAmount = _getAmountOut(baseToken, pool, reserveIn, reserveOut, twammReserveIn, twammReserveOut, fee);
        IFraxswap(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory 
    ) external override {
        address quoteToken = IFraxswap(pool).token1();
        (uint256 reserveOut, uint256 reserveIn, uint256 twammReserveOut, uint256 twammReserveIn, uint256 fee) = getReservesWithTwamm(pool);
        uint256 receiveBaseAmount = _getAmountOut(quoteToken, pool, reserveIn, reserveOut, twammReserveIn, twammReserveOut, fee);
        IFraxswap(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }
}
