// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IYearn.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract YearnAdapter is IAdapter {
    function _yEarnswap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));

        // get sellAmount
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);

        // swap
        if (pool == fromToken) {
            yVault(pool).withdraw(sellAmount);
        } else if (pool == toToken) {
            yVault(pool).deposit(sellAmount);
        } else {
            revert("pool address not match");
        }

        if (to != address(this)) {
            SafeERC20.safeTransfer(IERC20(toToken), to, IERC20(toToken).balanceOf(address(this)));
        }
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _yEarnswap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _yEarnswap(to, pool, moreInfo);
    }
}
