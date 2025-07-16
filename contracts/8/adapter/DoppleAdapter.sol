// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IDoppleSwap.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract DoppleAdapter is IAdapter {

    uint256 constant MIN_DY = 0;

    function _doppleSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (uint256 deadline, address fromToken, address toToken, uint8 sourceTokenIndex, uint8 targetTokenIndex) = abi.decode(
            moreInfo,
            (uint256, address, address, uint8, uint8)
        );
        uint256 dx = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(fromToken),
            pool,
            dx
        );
        IDoppleSwap(pool).swap(sourceTokenIndex, targetTokenIndex, dx, MIN_DY, deadline);
        SafeERC20.safeTransfer(
            IERC20(toToken),
            to,
            IERC20(toToken).balanceOf(address(this))
        );
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _doppleSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _doppleSwap(to, pool, moreInfo);
    }

}
