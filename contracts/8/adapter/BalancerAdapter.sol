// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../libraries/UniversalERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IBalancer.sol";

/// @title BalancerAdapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract BalancerAdapter is IAdapter {
    using UniversalERC20 for IERC20;

    function _balancerSwap(address to, address pool, bytes memory moreInfo) internal {
        (address tokenIn, address tokenOut) = abi.decode(moreInfo, (address, address));
        address[] memory currentToken = IBalancer(pool).getCurrentTokens();

        bool isTokenInInCurrentToken = false;
        bool isTokenOutInCurrentToken = false;

        for (uint i=0; i<currentToken.length; i++){
            if( currentToken[i] == tokenIn){ isTokenInInCurrentToken = true; }
            if( currentToken[i] == tokenOut){ isTokenOutInCurrentToken = true; }
        }
        require(isTokenInInCurrentToken == true, "BalancerAdapter: Wrong FromToken");
        require(isTokenOutInCurrentToken == true, "BalancerAdapter: Wrong ToToken");

        uint256 tokenAmountIn = IERC20(tokenIn).balanceOf(address(this));
        IERC20(tokenIn).approve(pool, tokenAmountIn);
        SafeERC20.safeApprove(IERC20(tokenIn), pool, tokenAmountIn);

        uint minAmountOut = 0; //Slippage
        uint maxPrice = 0; //Slippage
        
        IBalancer(pool).swapExactAmountIn(tokenIn, tokenAmountIn, tokenOut, minAmountOut, maxPrice);

        if(to != address(this)) {
            SafeERC20.safeTransfer(IERC20(tokenOut), to, IERC20(tokenOut).balanceOf(address(this)));
        }
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _balancerSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _balancerSwap(to, pool, moreInfo);
    }
}