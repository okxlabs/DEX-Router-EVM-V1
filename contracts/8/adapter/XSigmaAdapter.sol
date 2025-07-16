// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import {IXSigma} from "../interfaces/IXSigma.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract XSigmaAdapter is IAdapter {
    function _xSigmaSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (
        address fromToken,
        address toToken,
        int128 i,
        int128 j
        ) = abi.decode(moreInfo, (address, address, int128, int128));

        // get sellAmount
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(fromToken),
            pool,
            sellAmount
        );

        // swap
        IXSigma(pool).exchange(
            i,
            j,
            sellAmount,
            0
        );

        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(toToken),
                to,
                IERC20(toToken).balanceOf(address(this))
            );
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _xSigmaSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _xSigmaSwap(to, pool, moreInfo);
    }
}
