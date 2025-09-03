// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPolygonMigration {

    function migrate(uint256 amount) external;

    function unmigrate(uint256 amount) external;

    function unmigrateTo(address recipient, uint256 amount) external;
}
