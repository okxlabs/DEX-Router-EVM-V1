// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IRabbitRouter {

    function swapETHForExactTokens(uint256 amountOut, address to, uint256 deadline) external returns (uint256);

    function swapExactETHForTokens(uint256 amountOutMin, address to, uint256 deadline) external payable returns (uint256 amountOut);

    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address to, uint256 deadline) external returns (uint256 amountIn);

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) external returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);


}
