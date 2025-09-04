// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IExttload {
    function exttload(bytes32 slot) external view returns (bytes32 value);

    function exttload(bytes32[] calldata slots) external view returns (bytes32[] memory values);
}
