// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAlgebraSwapCallback {
    function algebraSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
