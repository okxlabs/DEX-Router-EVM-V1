// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface ISolidlyV3 {

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external returns (int256 amount0, int256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);


}
