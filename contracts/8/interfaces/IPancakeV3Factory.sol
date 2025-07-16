// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title The interface for the PancakeSwap V3 Factory
/// @notice The PancakeSwap V3 Factory facilitates creation of PancakeSwap V3 pools and control over the protocol fees
interface IPancakeV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}
