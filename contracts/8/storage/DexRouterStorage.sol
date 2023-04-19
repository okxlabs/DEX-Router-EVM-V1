// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DexRouterStorage {

    // In the test scenario, we take it as a settable state and adjust it to a constant after it stabilizes
    address public approveProxy;
    address public wNativeRelayer;
    mapping(address => bool) public priorityAddresses;
    uint256[19] internal _dexRouterGap;
    // Temporarily setting the admin address using a constant and then removing this variable.
    address public constant tmpAdmin = 0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87;
    address public admin;
}
