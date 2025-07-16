// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IPancakeV3SwapCallback.sol";
import "../interfaces/IPancakeV3Factory.sol";
import "../interfaces/IPancakeV3.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/TickMath.sol";
import "../interfaces/IWETH.sol";

/// @title PancakeV3Adapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract PancakeswapV3Adapter is IAdapter, IPancakeV3SwapCallback {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable FACTROY_ADDRESS;
    address public immutable WETH;

    constructor(address payable weth, address  _factory) {
        WETH = weth;
        FACTROY_ADDRESS = _factory;
    }

    function _pancakeAMMV3Swap(
        address to,
        address pool,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) internal {
        (address fromToken, address toToken, ) = abi.decode(
            data,
            (address, address, uint24)
        );

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroToOne = fromToken < toToken;

        IPancakeV3(pool).swap(
            to,
            zeroToOne,
            int256(sellAmount),
            sqrtPriceLimitX96 == 0
                ? (
                    zeroToOne
                        ? TickMath.MIN_SQRT_RATIO + 1
                        : TickMath.MAX_SQRT_RATIO - 1
                )
                : sqrtPriceLimitX96,
            data
        );
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 sqrtPriceLimitX96, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _pancakeAMMV3Swap(to, pool, sqrtPriceLimitX96, data);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 sqrtPriceLimitX96, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _pancakeAMMV3Swap(to, pool, sqrtPriceLimitX96, data);
    }

    // for uniV3 callback
    function pancakeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut, uint24 fee) = abi.decode( 
            _data,
            (address, address, uint24)
        );
        require(msg.sender == IPancakeV3Factory(FACTROY_ADDRESS).getPool(tokenIn,tokenOut,fee), "not allowed!");

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
            IWETH(WETH).deposit{value: value}(); // wrap only when it is needed to pay
            IWETH(WETH).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay through the ERC20tokens contract (for the exact input multihop case)
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            // pull payment
            SafeERC20.safeTransferFrom(IERC20(token), payer, recipient, value);
        }
    }
}
