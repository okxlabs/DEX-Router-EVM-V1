// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISmardex.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract SmardexAdapter is IAdapter, ISmardexSwapCallback {
    
    function _smardexSwap(
        address to,
        address pool,
        bytes memory data
    ) internal {
        (address fromToken, address toToken) = abi.decode(
            data,
            (address, address)
        );

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroForOne = fromToken < toToken;

        ISmardexPair(pool).swap(
            to,
            zeroForOne,
            int256(sellAmount),
            data
        );
    }
    
    
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _smardexSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _smardexSwap(to, pool, moreInfo);
    }

    function smardexSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut) = abi.decode(
            _data,
            (address, address)
        );

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));

        if (isExactInput) {
            SafeERC20.safeTransfer(IERC20(tokenIn), msg.sender, amountToPay);
        } else {
            tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
            SafeERC20.safeTransfer(IERC20(tokenIn), msg.sender, amountToPay);
        }
    }


} 