// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAlgebraSwapCallback.sol";
import "../interfaces/IAlgebra.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/TickMath.sol";
import "../interfaces/IWETH.sol";

/// @title AlgebraAdapter
/// @notice Adapter for Algebra v1, v1.9 and Algebra Integral, cause these versions share the same interface
/// @dev Explain to a developer any extra details
contract AlgebraAdapter is IAdapter, IAlgebraSwapCallback {
    address constant NATIVE_TOKEN_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WNATIVETOKEN;

    constructor(address payable wNativeToken) {
        WNATIVETOKEN = wNativeToken;
    }

    function _algebraSwap(
        address to,
        address pool,
        uint160 limitSqrtPrice, //limitSqrtPrice is same as sqrtPriceLimitX96 in uniswapv3
        bytes memory data
    ) internal {
        (address fromToken, address toToken) = abi.decode(
            data,
            (address, address)
        ); // data differs from uni, only pass two parameters

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroToOne = fromToken < toToken;

        IAlgebra(pool).swap(
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
        _algebraSwap(to, pool, limitSqrtPrice, data);
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
        _algebraSwap(to, pool, limitSqrtPrice, data);
    }

    // for algebra callback
    function algebraSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0, "Invalid amountDelta"); // swaps entirely within 0-liquidity regions are not supported
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
        if (token == WNATIVETOKEN && address(this).balance >= value) {
            // pay with native token
            IWETH(WNATIVETOKEN).deposit{value: value}(); // wrap only when it is needed to pay
            IWETH(WNATIVETOKEN).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay through the ERC20tokens contract (for the exact input multihop case)
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            // pull payment
            SafeERC20.safeTransferFrom(IERC20(token), payer, recipient, value);
        }
    }
}
