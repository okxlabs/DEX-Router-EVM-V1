// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

interface IDODOSwapCallback {
    function d3MMSwapCallBack(address token, uint256 value, bytes calldata data) external;
}
