// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INativeV3CreditVault {
    /// @notice Get the LP token address for a given underlying token
    /// @param underlyingToken The address of the underlying token
    /// @return lpToken The address of the LP token
    function lpTokens(address underlyingToken) external view returns (address);
}
