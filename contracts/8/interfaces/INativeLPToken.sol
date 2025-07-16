// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Interface for depositing and redeeming Native LP tokens
interface INativeLPToken {
    /// @notice Get the amount of LP tokens for a given address
    /// @param account Address to get the amount of LP tokens for
    /// @return shares Amount of LP tokens
    function sharesOf(address account) external returns (uint256 shares);

    /// @notice Deposit underlying tokens for a given address
    /// @param to Address to mint LP tokens to
    /// @param amount Amount of underlying tokens to deposit
    /// @return sharesToMint Amount of LP tokens minted
    function depositFor(address to, uint256 amount) external returns (uint256 sharesToMint);

    /// @notice Redeem LP tokens for underlying tokens to a given address
    /// @param sharesToBurn Amount of LP tokens to burn
    /// @param to Address to receive the underlying tokens
    /// @return underlyingAmount Amount of underlying tokens received
    function redeemTo(uint256 sharesToBurn, address to) external returns (uint256 underlyingAmount);

    /// @notice Get the underlying token address
    /// @return underlyingToken Address of the underlying token
    function underlying() external returns (address underlyingToken);

    /// @notice Calculates the number of shares for a given amount of underlying tokens
    /// @param underlyingAmount The amount of underlying tokens to convert
    /// @return The corresponding number of shares
    function getSharesByUnderlying(uint256 underlyingAmount) external view returns (uint256);

    /// @notice Calculates the underlying token amount for a given number of shares
    /// @param sharesAmount The number of shares to convert
    /// @return The corresponding amount of underlying tokens
    function getUnderlyingByShares(uint256 sharesAmount) external view returns (uint256);
}
