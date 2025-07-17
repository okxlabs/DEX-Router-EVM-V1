// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IVirtuSwap {
    function fee() external view returns (uint256);

    function token0() external view returns (address);

    function pairBalance0() external view returns (uint256);

    function pairBalance1() external view returns (uint256);

    function swapNative(
        uint256 amountOut,
        address tokenOut,
        address to,
        bytes calldata data
    ) external returns (uint256 _amountIn);
}
