// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWooPPV2.sol";
import "../libraries/SafeERC20.sol";

contract WoofiAdapter is IAdapter {

    function _woofiSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));
        uint256 fromAmount = IERC20(fromToken).balanceOf(address(this));
        
        SafeERC20.safeTransfer(IERC20(fromToken), pool, fromAmount);
        IWooPPV2(pool).swap(
            fromToken,
            toToken,
            fromAmount,
            0,
            to,
            to
        );
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _woofiSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _woofiSwap(to, pool, moreInfo);
    }
}