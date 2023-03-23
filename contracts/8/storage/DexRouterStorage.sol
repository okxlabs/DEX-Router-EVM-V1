// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DexRouterStorage {

    // In the test scenario, we take it as a settable state and adjust it to a constant after it stabilizes
    address public approveProxy;
    address public wNativeRelayer;
    mapping(address => bool) public priorityAddresses;
    uint256[19] internal _dexRouterGap;
    // Temporarily setting the admin address using a constant and then removing this variable.
    address public constant tmpAdmin = 0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6;
    address public admin;
}
