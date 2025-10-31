// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IFluidDexLite
 * @dev Interface for the FluidDexLite contract
 */
interface IFluidDexLite {
    struct DexKey {
        address token0;
        address token1;
        bytes32 salt;
    }

    /// @notice Swap through a single dex pool
    /// @dev Uses _swapIn for positive amountSpecified_ (user provides input), _swapOut for negative (user receives output).
    /// @param dexKey_ The dex pool to swap through.
    /// @param swap0To1_ Whether to swap from token0 to token1 or vice versa.
    /// @param amountSpecified_ The amount to swap (positive for exact input, negative for exact output).
    /// @param amountLimit_ The minimum/maximum amount for the unspecified side.
    /// @param to_ The recipient address.
    function swapSingle(
        DexKey calldata dexKey_,
        bool swap0To1_,
        int256 amountSpecified_,
        uint256 amountLimit_,
        address to_,
        bool isCallback_,
        bytes calldata callbackData_,
        bytes calldata extraData_
    ) external payable;
}
