// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IOSwap.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract OriginAdapter is IAdapter {

    function _OSwap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));
        uint256 amountIn = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, amountIn);
        IOSwap(pool).swapExactTokensForTokens(IERC20(fromToken), IERC20(toToken), amountIn, 0, to);
    }

    function sellBase(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _OSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _OSwap(to, pool, moreInfo);
    }
}