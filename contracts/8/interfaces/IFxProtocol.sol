/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IFxMarket {

  /// @notice Mint both fToken and xToken with some base token.
  /// @param baseIn The amount of base token supplied.
  /// @param recipient The address of receiver for fToken and xToken.
  /// @param minFTokenMinted The minimum amount of fToken should be received.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return fTokenMinted The amount of fToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function mint(
    uint256 baseIn,
    address recipient,
    uint256 minFTokenMinted,
    uint256 minXTokenMinted
  ) external returns (uint256 fTokenMinted, uint256 xTokenMinted);

  /// @notice Mint some fToken with some base token.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for fToken.
  /// @param minFTokenMinted The minimum amount of fToken should be received.
  /// @return fTokenMinted The amount of fToken should be received.
  function mintFToken(
    uint256 baseIn,
    address recipient,
    uint256 minFTokenMinted
  ) external returns (uint256 fTokenMinted);

  /// @notice Mint some xToken with some base token.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for xToken.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  /// @return bonus The amount of base token as bonus.
  function mintXToken(
    uint256 baseIn,
    address recipient,
    uint256 minXTokenMinted
  ) external returns (uint256 xTokenMinted, uint256 bonus);


  /// @notice Redeem base token with fToken and xToken.
  /// @param fTokenIn the amount of fToken to redeem, use `uint256(-1)` to redeem all fToken.
  /// @param xTokenIn the amount of xToken to redeem, use `uint256(-1)` to redeem all xToken.
  /// @param recipient The address of receiver for base token.
  /// @param minBaseOut The minimum amount of base token should be received.
  /// @return baseOut The amount of base token should be received.
  function redeem(
    uint256 fTokenIn,
    uint256 xTokenIn,
    address recipient,
    uint256 minBaseOut
  ) external returns (uint256 baseOut);

}