// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";

interface ITellerWithMultiAssetSupport {
    /// @notice Allows users to deposit into the BoringVault
    /// @param depositAsset The token to deposit
    /// @param depositAmount The amount to deposit
    /// @param minimumMint The minimum amount of shares to mint
    /// @return shares The amount of shares minted
    function deposit(
        IERC20 depositAsset,
        uint256 depositAmount,
        uint256 minimumMint
    ) external payable returns (uint256 shares);

    /// @notice Allows users to deposit into BoringVault using permit
    /// @param depositAsset The token to deposit
    /// @param depositAmount The amount to deposit
    /// @param minimumMint The minimum amount of shares to mint
    /// @param deadline The deadline for the permit signature
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return shares The amount of shares minted
    function depositWithPermit(
        IERC20 depositAsset,
        uint256 depositAmount,
        uint256 minimumMint,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 shares);
}
