// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICameplotPair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint16 _token0FeePercent, uint16 _token1FeePercent) ;

    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external ;

    function token0() external view returns (address);

    function token1() external view returns (address);
}
