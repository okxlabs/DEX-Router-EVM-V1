// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Polygon Migration
/// @author Polygon Labs (@DhairyaSethi, @gretzke, @qedk)
/// @notice This is the migration contract for Matic <-> Polygon ERC20 token on Ethereum L1
/// @dev The contract allows for a 1-to-1 conversion from $MATIC into $POL and vice-versa
/// @custom:security-contact security@polygon.technology
interface IPolygonMigration {

    /// @notice this function allows for migrating MATIC tokens to POL tokens
    /// @param amount amount of MATIC to migrate
    /// @dev the function does not do any validation since the migration is a one-way process
    function migrate(uint256 amount) external;

    /// @notice this function allows for unmigrating from POL tokens to MATIC tokens
    /// @param amount amount of POL to migrate
    /// @dev the function can only be called when unmigration is unlocked (lock updatable by governance)
    /// @dev the function does not do any further validation, also note the unmigration is a reversible process
    function unmigrate(uint256 amount) external;

    /// @notice this function allows for unmigrating POL tokens (from msg.sender) to MATIC tokens (to account)
    /// @param recipient address to receive MATIC tokens
    /// @param amount amount of POL to migrate
    /// @dev the function can only be called when unmigration is unlocked (lock updatable by governance)
    /// @dev the function does not do any further validation, also note the unmigration is a reversible process
    function unmigrateTo(address recipient, uint256 amount) external;
}