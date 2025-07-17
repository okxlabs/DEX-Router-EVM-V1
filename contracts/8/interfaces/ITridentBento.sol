// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IERC20.sol";

interface ITridentBento {
    struct Rebase {
        uint128 elastic;
        uint128 base;
    }
    
    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function balanceOf(IERC20 token, address account) external view returns (uint256);
    
    //function totals(IERC20 token) external view returns (Rebase memory);
    
}
