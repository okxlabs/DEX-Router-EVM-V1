// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PMMRouterStorage {
    uint256[6] private slots_UNUSED; // to take over 6 slots
    // pmm payer => pmm operator
    mapping(address => address) public operator_UNUSED;
    mapping(bytes32 => uint256) public orderRemaining_UNUSED;
    uint256 public feeRateAndReceiver_UNUSED; // 2bytes feeRate + 0000... + 20bytes feeReceiver
    uint256[50] internal _pmmRouterGap_UNUSED;
}
