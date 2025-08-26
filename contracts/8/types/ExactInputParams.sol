// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Parameters for swapExactInput function
/// @param inputToken The token to swap from
/// @param outputToken The token to swap to
/// @param inputAmount The exact amount of inputToken to swap
/// @param outputAmountMin The minimum amount of outputToken expected
/// @param recipient The address to receive the output tokens
/// @param deadline The deadline for the swap

struct ExactInputParams {
    /// @notice The address of the input token (use address(0) for native asset)
    address inputToken;
    /// @notice The address of the output token (use address(0) for native asset)
    address outputToken;
    /// @notice The amount of input token to swap (in input token decimals)
    uint256 inputAmount;
    /// @notice The minimum amount of output token to receive
    uint256 minOutputAmount;
    /// @notice Optional permit data for the input token (can be empty)
    bytes permitData;
}