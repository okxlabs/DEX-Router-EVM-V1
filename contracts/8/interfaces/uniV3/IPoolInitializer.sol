// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

interface IPoolInitializer {
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}
