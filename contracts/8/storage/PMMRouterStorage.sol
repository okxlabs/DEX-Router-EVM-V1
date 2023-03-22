// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PMMRouterStorage {
    // pmm payer => pmm operator
    mapping(address => address) public operator;
    mapping(bytes32 => uint256) public orderRemaining;
    uint256 public feeRateAndReceiver;    // 2bytes feeRate + 0000... + 20bytes feeReceiver
    uint256[50] internal _pmmRouterGap;
    
}
