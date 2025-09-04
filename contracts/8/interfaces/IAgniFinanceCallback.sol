// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAgniFinanceCallback {
    function agniSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
