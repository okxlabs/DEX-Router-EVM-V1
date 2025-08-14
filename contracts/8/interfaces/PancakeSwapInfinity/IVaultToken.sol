//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Currency} from "../../types/Currency.sol";

/// @notice Interface for vault token operations
interface IVaultToken {
    /// @notice Returns the balance of a specific currency for a given address
    function balanceOf(address owner, Currency currency) external view returns (uint256 balance);

    /// @notice Returns the total supply of a specific currency
    function totalSupply(Currency currency) external view returns (uint256);
} 