// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAlgebraSwapCallback.sol";
import "../interfaces/IUniswapV3SwapCallback.sol";
import "../interfaces/IQuickV3.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/TickMath.sol";
import "../interfaces/IWETH.sol";

/// @title QuickswapV3Adapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract Quickswapv3Adapter is IAdapter, IAlgebraSwapCallback, IUniswapV3SwapCallback {
    address constant MATIC_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WMATIC;

    constructor(address payable wmatic) {
        WMATIC = wmatic;
    }

    function _quickV3Swap(
        address to,
        address pool,
        uint160 limitSqrtPrice,//limitSqrtPrice is same as sqrtPriceLimitX96 in uniswapv3
        bytes memory data
    ) internal {
        (address fromToken, address toToken ) = abi.decode(
            data,
            (address, address)
        );//data和uni不同，只传两个

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroToOne = fromToken < toToken;

        IQuickV3(pool).swap(
            to,
            zeroToOne,
            int256(sellAmount),
            limitSqrtPrice == 0
                ? (
                    zeroToOne
                        ? TickMath.MIN_SQRT_RATIO + 1
                        : TickMath.MAX_SQRT_RATIO - 1
                )
                : limitSqrtPrice,
            data
        );
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 limitSqrtPrice, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _quickV3Swap(to, pool, limitSqrtPrice, data);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 limitSqrtPrice, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _quickV3Swap(to, pool, limitSqrtPrice, data);
    }

    // for algebra callback
    function algebraSwapCallback(
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
            pay(tokenIn, address(this), msg.sender, amountToPay);
        } else {
            tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
            pay(tokenIn, address(this), msg.sender, amountToPay);
        }
    }

    // for uniV3 callback
    function uniswapV3SwapCallback(
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
            pay(tokenIn, address(this), msg.sender, amountToPay);
        } else {
            tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
            pay(tokenIn, address(this), msg.sender, amountToPay);
        }
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == WMATIC && address(this).balance >= value) {
            // pay with WETH9
            IWETH(WMATIC).deposit{value: value}(); // wrap only when it is needed to pay
            IWETH(WMATIC).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay through the ERC20tokens contract (for the exact input multihop case)
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            // pull payment
            SafeERC20.safeTransferFrom(IERC20(token), payer, recipient, value);
        }
    }
}
