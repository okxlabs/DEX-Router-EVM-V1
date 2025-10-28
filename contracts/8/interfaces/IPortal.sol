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

/// @title IPortal - Simplified interface for Portal swapExactInput functions
/// @notice Interface containing only the swapExactInput functions and related parameters
interface IPortal {

    /// @notice Parameters for swapping exact input amount for output token (V3) with extension support
    struct ExactInputV3Params {
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
        /// @notice Additional extension specific data to be passed to the extension's `onTrade` method, check the extension's documentation for details on the expected format and content
        bytes extensionData;
    }

    /// @notice Parameters for quoteExactInput function
    /// @param inputToken The token to swap from
    /// @param outputToken The token to swap to
    /// @param inputAmount The exact amount of inputToken to quote
    struct QuoteExactInputParams {
        address inputToken;
        address outputToken;
        uint256 inputAmount;
    }

    /// @notice Swap an exact amount of input tokens for output tokens
    /// @param params The swap parameters
    /// @return outputAmount The amount of output tokens received
    function swapExactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 outputAmount);

    /// @notice Swap an exact amount of input tokens for output tokens
    /// @param params The swap parameters including extension data
    /// @return outputAmount The amount of output tokens received
    function swapExactInputV3(ExactInputV3Params calldata params)
        external
        payable
        returns (uint256 outputAmount);

    /// @notice Quote the output amount for an exact input swap
    /// @param params The quote parameters
    /// @return outputAmount The estimated amount of output tokens
    function quoteExactInput(QuoteExactInputParams calldata params)
        external
        returns (uint256 outputAmount);
}
