// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAlgebra {
    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback#algebraSwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountRequired The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback. If using the Router it should contain SwapRouter#SwapCallbackData
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroToOne,
        int256 amountRequired,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);
}
