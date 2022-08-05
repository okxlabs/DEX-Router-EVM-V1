

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IShell} from "../interfaces/IShell.sol";
import {IAdapter} from "../interfaces/IAdapter.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract ShellAdapter is IAdapter {

    function _shellSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken, uint256 _deadline) = abi.decode(
            moreInfo,
            (address, address, uint256)
        );
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);

        IShell(pool).originSwap(fromToken, toToken, sellAmount, 0, _deadline);

        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(toToken),
                to,
                IERC20(toToken).balanceOf(address(this))
            );
        }
    }

    function sellBase( address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _shellSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _shellSwap(to, pool, moreInfo);
    }
}
