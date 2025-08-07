// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2024 PancakeSwap
pragma solidity ^0.8.0;

import {IVault} from "./IVault.sol";

/// @title Immutable State Interface
/// @notice Functions for getting the vault address
interface IImmutableState {
    /// @return Returns the vault
    function vault() external view returns (IVault);
} 