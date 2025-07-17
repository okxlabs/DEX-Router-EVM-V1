// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IXeiV3SwapCallback.sol";
import "../interfaces/IUniV3.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/TickMath.sol";
import "../interfaces/IWETH.sol";

/// @title XeiAdapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract XeiAdapter is IAdapter, IXeiV3SwapCallback {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WETH;

    constructor(address payable weth) {
        WETH = weth;
    }

    function _xeiSwap(
        address to,
        address pool,
        uint160 sqrtX96,
        bytes memory data
    ) internal {
        (address fromToken, address toToken, ) = abi.decode(
            data,
            (address, address, uint24)
        );

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroForOne = fromToken < toToken;

        IUniV3(pool).swap(
            to,
            zeroForOne,
            int256(sellAmount),
            sqrtX96 == 0
                ? (
                    zeroForOne
                        ? TickMath.MIN_SQRT_RATIO + 1
                        : TickMath.MAX_SQRT_RATIO - 1
                )
                : sqrtX96,
            data
        );
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 sqrtX96, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _xeiSwap(to, pool, sqrtX96, data);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 sqrtX96, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _xeiSwap(to, pool, sqrtX96, data);
    }

    // for Xei callback
    function xeiV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut, ) = abi.decode(
            _data,
            (address, address, uint24)
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
        if (token == WETH && address(this).balance >= value) {
            // pay with WETH9
            IWETH(WETH).deposit{value: value}(); // wrap only what is needed to pay
            IWETH(WETH).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            // pull payment
            SafeERC20.safeTransferFrom(IERC20(token), payer, recipient, value);
        }
    }
}