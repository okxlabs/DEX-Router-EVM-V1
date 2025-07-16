// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/INerveFinance.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract NerveFinanceAdapter is IAdapter {

    function _nerveSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken, uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 deadline) = abi.decode(
            moreInfo,
            (address, address, uint8, uint8, uint256)
        );

        uint256 sellAmount = 0;
        sellAmount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);

        INerveFinance(pool).swap(tokenIndexFrom, tokenIndexTo, sellAmount, 0, deadline);

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
        _nerveSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _nerveSwap(to, pool, moreInfo);
    }

}
