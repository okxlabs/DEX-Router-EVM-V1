// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IFewERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IFewWrappedToken.sol";
import "../interfaces/IUniswapV3SwapCallback.sol";
import "../interfaces/IUniV3.sol";
import "../libraries/TickMath.sol";
import "../interfaces/IWETH.sol";

/// @title RingV3Adapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract RingV3Adapter is IAdapter, IUniswapV3SwapCallback {
    address internal constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WETH;

    constructor(address payable weth) {
        WETH = weth;
    }

    function _ringV3Swap(
        address to,
        address pool,
        address fwTokenOut,
        uint160 sqrtX96,
        bytes memory data
    ) internal {
        (address fromToken, address toToken, ) = abi.decode(
            data,
            (address, address, uint24)
        );
        address token0 = IUniV3(pool).token0();
        bool zeroForOne;
        fromToken == IFewWrappedToken(token0).token()
            ? zeroForOne = true
            : zeroForOne = false;
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        
        IUniV3(pool).swap(
            address(this),
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
       
        
        IFewWrappedToken(fwTokenOut).unwrapTo(
            IFewERC20(fwTokenOut).balanceOf(address(this)),
            to
        ); //unwrap and transfer
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        address quoteToken = IUniV3(pool).token1();
        (uint160 sqrtX96, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );

        _ringV3Swap(to, pool, quoteToken, sqrtX96, data);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        address baseToken = IUniV3(pool).token0();
        (uint160 sqrtX96, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _ringV3Swap(to, pool, baseToken, sqrtX96, data);
    }

    // for ringV3Swap callback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut, ) = abi.decode(
            _data,
            (address, address, uint24)
        );
        address baseToken = IUniV3(msg.sender).token0();
        address quoteToken = IUniV3(msg.sender).token1();
        address fwToken;
        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (
                tokenIn == IFewWrappedToken(baseToken).token(),
                uint256(amount0Delta)
            )
            : (
                tokenOut == IFewWrappedToken(baseToken).token(),
                uint256(amount1Delta)
            );
        if (isExactInput) {
        
            tokenIn == IFewWrappedToken(baseToken).token()
                ? fwToken = baseToken
                : fwToken = quoteToken;
            pay(tokenIn, fwToken, msg.sender, amountToPay);
        } else {
            tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
            tokenIn == IFewWrappedToken(baseToken).token()
                ? fwToken = baseToken
                : fwToken = quoteToken;
            pay(tokenIn, quoteToken, msg.sender, amountToPay);
        }
    }

    /// @param token The token to pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address fwToken,
        address recipient,
        uint256 value
    ) internal {
        if (token == WETH && address(this).balance >= value) {
            // pay with WETH9
            IWETH(WETH).deposit{value: value}(); // wrap only what is needed to pay
        }
        
        SafeERC20.safeApprove(IERC20(token), fwToken, value);
        IFewWrappedToken(fwToken).wrapTo(value, recipient); //wrap and transfer
    }
}
