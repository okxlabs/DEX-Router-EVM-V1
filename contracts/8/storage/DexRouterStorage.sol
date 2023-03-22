// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DexRouterStorage {

    // In the test scenario, we take it as a settable state and adjust it to a constant after it stabilizes
    address public approveProxy;
    address public wNativeRelayer;
    address public xBridge;
    uint256[20] internal _dexRouterGap;
    
}
