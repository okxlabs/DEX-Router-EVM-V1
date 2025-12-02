/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

interface IBonding {

    function buy(
        uint256 amountIn,
        address tokenAddress
    ) external payable returns (bool) ;

    function buy(
        uint256 amountIn,
        address tokenAddress,
        uint256 amountOutMin,
        uint256 deadline
    ) external payable returns (bool) ;

    function sell(
        uint256 amountIn,
        address tokenAddress
    ) external returns (bool) ;

    function sell(
        uint256 amountIn,
        address tokenAddress,
        uint256 amountOutMin,
        uint256 deadline
    ) external returns (bool) ;

}
