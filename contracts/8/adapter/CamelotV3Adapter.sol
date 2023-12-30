// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IAdapter.sol";
import "../interfaces/IAlgebraSwapCallback.sol";
import "../interfaces/ICamelotV3Pool.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/TickMath.sol";

contract CamelotV3Adapter is IAdapter, IAlgebraSwapCallback {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public immutable WETH;

    // weth in arb: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
    constructor(address payable weth) {
        WETH = weth;
    }

    function _camelotV3Swap(
        address to,
        address pool,
        uint160 limitSqrtPrice,
        bytes memory data
    ) internal {
        (address tokenIn, address tokenOut) = abi.decode(
            data,
            (address, address)
        );

        uint256 sellAmount = IERC20(tokenIn).balanceOf(address(this));
        bool zeroToOne = tokenIn < tokenOut;

        ICamelotV3Pool(pool).swap(
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

    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
       (uint160 limitSqrtPrice, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );

        _camelotV3Swap(to, pool, limitSqrtPrice, data);
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 limitSqrtPrice, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );

        _camelotV3Swap(to, pool, limitSqrtPrice, data);
    }

    // for uniV3 callback
    function algebraSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0, "amount error"); // swaps entirely within 0-liquidity regions are not supported
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
        if (token == WETH && address(this).balance >= value) {
            // pay with WETH9
            IWETH(WETH).deposit{value: value}(); // wrap only when it is needed to pay
            IWETH(WETH).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay through the ERC20tokens contract (for the exact input multihop case)
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            revert("can not reach here");
        }
    }
}