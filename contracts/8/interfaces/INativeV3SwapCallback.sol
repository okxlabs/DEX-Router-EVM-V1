// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Callback for INativeV3PoolActions#swap
/// @notice Any contract that calls INativeV3PoolActions#swap must implement this interface
interface INativeV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via INativeV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a NativeV3Pool deployed by the canonical NativeV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the INativeV3PoolActions#swap call
    function nativeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
