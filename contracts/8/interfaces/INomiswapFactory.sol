// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface INomiswapFactory {

    function getPair(address token0, address token1) external view returns (address);
}
