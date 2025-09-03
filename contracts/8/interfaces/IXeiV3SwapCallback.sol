// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IXeiV3SwapCallback {
    function xeiV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}
