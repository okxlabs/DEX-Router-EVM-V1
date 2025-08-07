// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2024 PancakeSwap
pragma solidity ^0.8.0;

import {IVault} from "../../interfaces/PancakeSwapInfinity/IVault.sol";
import {IImmutableState} from "../../interfaces/PancakeSwapInfinity/IImmutableState.sol";

/// @title Immutable State
/// @notice A collection of immutable state variables, commonly used across multiple contracts
contract ImmutableState is IImmutableState {
    /// @inheritdoc IImmutableState
    IVault public immutable vault;

    constructor(IVault _vault) {
        vault = _vault;
    }
} 