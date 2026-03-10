// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IFluidDexLiteCallback
 * @dev Interface for the callback function of the FluidDexLite contract
 */
interface IFluidDexLiteCallback {
    /// @notice Callback function for the dex pool
    /// @dev This function is called by the dex pool to pay the tokenIn.
    /// @param token_ The token to pay.
    /// @param amount_ The amount to pay.
    /// @param data_ The data to execute.
    function dexCallback(address token_, uint256 amount_, bytes calldata data_) external;
}
