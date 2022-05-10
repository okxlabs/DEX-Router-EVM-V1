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

    function _balancerSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address sourceToken, address targetToken) = abi.decode(
            moreInfo,
            (address, address)
        );
        address[] memory currentToken = IBalancer(pool).getCurrentTokens();

        bool isTokenInInCurrentToken = false;
        bool isTokenOutInCurrentToken = false;

        for (uint256 i = 0; i < currentToken.length; i++) {
            if (currentToken[i] == sourceToken) {
                isTokenInInCurrentToken = true;
            }
            if (currentToken[i] == targetToken) {
                isTokenOutInCurrentToken = true;
            }
        }
        require(
            isTokenInInCurrentToken == true,
            "BalancerAdapter: Wrong FromToken"
        );
        require(
            isTokenOutInCurrentToken == true,
            "BalancerAdapter: Wrong ToToken"
        );

        uint256 tokenAmountIn = IERC20(sourceToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(sourceToken), pool, tokenAmountIn);

        IBalancer(pool).swapExactAmountIn(
            sourceToken,
            tokenAmountIn,
            targetToken,
            0,
            type(uint256).max
        );

        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(targetToken),
                to,
                IERC20(targetToken).balanceOf(address(this))
            );
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _balancerSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _balancerSwap(to, pool, moreInfo);
    }
}
