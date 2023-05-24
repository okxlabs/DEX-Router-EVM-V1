// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAxialPool.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";


contract AxialAdapter is IAdapter {

    function _axialSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (uint256 deadline, address fromToken, address toToken, uint8 sourceTokenIndex, uint8 targetTokenIndex) = abi.decode(
            moreInfo,
            (uint256, address, address, uint8, uint8)
        );

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);
        IAxialPool(pool).swap(
            sourceTokenIndex,
            targetTokenIndex,
            sellAmount,
            0,
            deadline
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
        _axialSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _axialSwap(to, pool, moreInfo);
    }

}
