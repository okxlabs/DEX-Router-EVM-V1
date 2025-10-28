// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title AAVE lending pool on AVAX chain.
/// @notice you can refer to https://snowtrace.io/address/0x01ae7DDA024eA9712344D9332c94d3168a91f342#code
interface ILendingPool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
    
    function deposit(
      address asset,
      uint256 amount,
      address onBehalfOf,
      uint16 referralCode
    ) external;
}
