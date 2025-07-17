// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/SafeERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/IVirtuSwap.sol";

contract VirtuSwapAdapter is IAdapter {
    uint24 internal constant PRICE_FEE_FACTOR = 10 ** 3;
    using SafeERC20 for IERC20;

    function _getAmountOut(
        uint256 amountIn,
        uint256 pairBalanceIn,
        uint256 pairBalanceOut,
        uint256 fee
    ) private pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * fee;
        uint256 numerator = amountInWithFee * pairBalanceOut;
        uint256 denominator = (pairBalanceIn * PRICE_FEE_FACTOR) +
            amountInWithFee;
        amountOut = numerator / denominator;
    }

    function _virtuSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) private {
        uint256 amountOut;
        (address tokenIn, address tokenOut) = abi.decode(
            moreInfo,
            (address, address)
        );

        //calcualte amountOut
        {
            uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
            address token0 = IVirtuSwap(pool).token0();
            uint256 pairBalance0 = IVirtuSwap(pool).pairBalance0();
            uint256 pairBalance1 = IVirtuSwap(pool).pairBalance1();
            uint256 fee = IVirtuSwap(pool).fee();

            (uint256 pairBalanceIn, uint256 pairBalanceOut) = tokenIn == token0
                ? (pairBalance0, pairBalance1)
                : (pairBalance1, pairBalance0);

            amountOut = _getAmountOut(
                amountIn,
                pairBalanceIn,
                pairBalanceOut,
                fee
            );

            IERC20(tokenIn).safeTransfer(pool, amountIn);
        }

        IVirtuSwap(pool).swapNative(amountOut, tokenOut, to, "");
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _virtuSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _virtuSwap(to, pool, moreInfo);
    }
}
