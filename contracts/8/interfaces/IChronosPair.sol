// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChronosPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast);
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}
