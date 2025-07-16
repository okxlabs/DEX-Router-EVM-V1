// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IHtoken.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract HtokenAdapter is IAdapter {

    function _htokenSwap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));
        uint8 fromTokenIndex = IHtoken(pool).getTokenIndex(fromToken);
        uint8 toTokenIndex = IHtoken(pool).getTokenIndex(toToken);
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        // approve
        SafeERC20.safeApprove(IERC20(fromToken),  pool, sellAmount);
        // swap
        IHtoken(pool).swap(fromTokenIndex, toTokenIndex, sellAmount, 0, block.timestamp);
        if(to != address(this)) {
            SafeERC20.safeTransfer(IERC20(toToken), to, IERC20(toToken).balanceOf(address(this)));
        }
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _htokenSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _htokenSwap(to, pool, moreInfo);
    }
}