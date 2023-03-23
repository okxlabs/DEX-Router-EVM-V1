// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface ISolidly {
    struct route {
        address from;
        address to;
        bool stable;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] memory routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) ;
}
