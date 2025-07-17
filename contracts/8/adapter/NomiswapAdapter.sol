// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/INomiswapStable.sol";
import "../interfaces/INomiswapFactory.sol";
import "../interfaces/IERC20.sol";

/// @title NomiswapStableAdapter
/// @notice NomiswapStable on ETH, and only has two pairs now.DAI-USDT,USDC-USDT.
/// @dev The NomiswapStableFactory has two pairs, but NomiswapFactory only has one pair without liquidity.
contract NomiswapAdapter is IAdapter {
    // fromToken == token0
    address public immutable NomiswapStableFactory;
    address public immutable NomiswapFactory;
    constructor(address _NomiswapFactory, address _NomiswapStableFactory) {
        NomiswapStableFactory = _NomiswapStableFactory;// Address of NomiswapStableFactory is 0x818339b4E536E707f14980219037c5046b049dD4;
        NomiswapFactory = _NomiswapFactory;// Address of NomiswapFactory is 0xEfD2f571989619a942Dc3b5Af63866B57D1869ED;
    }
    
    function sellBase(
        address to,
        address pool,
        bytes memory
    ) external override {
        address baseToken = INomiswapStable(pool).token0();
        address quoteToken = INomiswapStable(pool).token1();
        (uint256 reserveIn, uint256 reserveOut, ) = INomiswapStable(pool).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "NomiswapAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0 = IERC20(baseToken).balanceOf(pool);
        uint256 sellBaseAmount = balance0 - reserveIn; 

        address pair = INomiswapFactory(NomiswapStableFactory).getPair(baseToken, quoteToken);
        if (pair != address(0)) { 
            uint256 receiveQuoteAmount = INomiswapStable(pool).getAmountOut(baseToken, sellBaseAmount);
            INomiswapStable(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
        } else {
            revert("This pair does not exist in the nomiswapstablefactory");
        }   
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory
    ) external override {
        address quoteToken = INomiswapStable(pool).token1();
        address baseToken = INomiswapStable(pool).token0();
        (uint256 reserveOut, uint256 reserveIn, ) = INomiswapStable(pool).getReserves();
        require(
            reserveIn > 0 && reserveOut > 0,
            "nomiAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance1 = IERC20(quoteToken).balanceOf(pool);
        uint256 sellQuoteAmount = balance1 - reserveIn;

        address pair = INomiswapFactory(NomiswapStableFactory).getPair(baseToken, quoteToken);
        if (pair != address(0)) {
            uint256 receiveBaseAmount = INomiswapStable(pool).getAmountOut(quoteToken, sellQuoteAmount);
            INomiswapStable(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
        } else {
            revert("This pair does not exist in the nomiswapstablefactory");
        }
    }
}
