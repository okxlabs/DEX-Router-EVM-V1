// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC6909Claims
/// @notice Interface for ERC6909 Claims functionality
interface IERC6909Claims {
    /// @notice Get the balance of a specific token for an account
    /// @param owner The address to query
    /// @param id The token identifier
    /// @return The balance of the token
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /// @notice Get the allowance for a specific token between owner and spender
    /// @param owner The owner of the tokens
    /// @param spender The address authorized to spend
    /// @param id The token identifier
    /// @return The allowance amount
    function allowance(address owner, address spender, uint256 id) external view returns (uint256);

    /// @notice Check if an operator is approved for all tokens of an owner
    /// @param owner The owner of the tokens
    /// @param operator The operator address
    /// @return True if operator is approved for all
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
