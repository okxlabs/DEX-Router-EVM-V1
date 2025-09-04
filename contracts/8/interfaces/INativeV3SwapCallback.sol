// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INativeV3SwapCallback {
    function nativeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
