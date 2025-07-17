// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/INexttoken.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract NexttokenAdapter is IAdapter {

    function _nextTokenSwap(address to, address pool, bytes memory moreInfo) internal {
        bytes32 key;
        address fromToken;
        address toToken;
        assembly {
            key := mload(add(moreInfo, 0x20))
            fromToken := mload(add(moreInfo, 0x34))
            toToken := mload(add(moreInfo, 0x48))
        }
        uint8 fromTokenIndex = INexttoken(pool).getSwapTokenIndex(key, fromToken);
        uint8 toTokenIndex = INexttoken(pool).getSwapTokenIndex(key, toToken);
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        // approve
        SafeERC20.safeApprove(IERC20(fromToken),  pool, sellAmount);
        // swap
        INexttoken(pool).swap(key, fromTokenIndex, toTokenIndex, sellAmount, 0, block.timestamp);
        if(to != address(this)) {
            SafeERC20.safeTransfer(IERC20(toToken), to, IERC20(toToken).balanceOf(address(this)));
        }
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _nextTokenSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _nextTokenSwap(to, pool, moreInfo);
    }
}