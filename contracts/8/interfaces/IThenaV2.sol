// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IThenaV2 {
    /**
    * @notice The first of the two tokens of the pool, sorted by address
    * @return The token contract address
    */
    function token0() external view returns (address);

    /**
    * @notice The second of the two tokens of the pool, sorted by address
    * @return The token contract address
    */
    function token1() external view returns (address);

    /**
    * @notice Swap token0 for token1, or token1 for token0
    * @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback# AlgebraSwapCallback
    * @param recipient The address to receive the output of the swap
    * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
    * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    * value after the swap. If one for zero, the price cannot be greater than this value after the swap
    * @param data Any data to be passed through to the callback. If using the Router it should contain
    * SwapRouter#SwapCallbackData
    * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    */
    function swap(
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /**
    * @notice The globalState structure in the pool stores many values but requires only one slot
    * and is exposed as a single method to save gas when accessed externally.
    * @return price The current price of the pool as a sqrt(token1/token0) Q64.96 value;
    * Returns tick The current tick of the pool, i.e. according to the last tick transition that was run;
    * Returns This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick
    * boundary;
    * Returns fee The last pool fee value in hundredths of a bip, i.e. 1e-6;
    * Returns timepointIndex The index of the last written timepoint;
    * Returns communityFeeToken0 The community fee percentage of the swap fee in thousandths (1e-3) for token0;
    * Returns communityFeeToken1 The community fee percentage of the swap fee in thousandths (1e-3) for token1;
    * Returns unlocked Whether the pool is currently locked to reentrancy;
    */
    function globalState()
    external
    view
    returns (
        uint160 price,
        int24 tick,
        uint16 fee,
        uint16 timepointIndex,
        uint8 communityFeeToken0,
        uint8 communityFeeToken1,
        bool unlocked
    );

}