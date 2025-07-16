// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISmoothyV1.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

contract SmoothyV1Adapter is IAdapter {

    address constant SMOOTHY = 0xe5859f4EFc09027A9B718781DCb2C6910CAc6E91;

    function _swap(
        address to,
        address /*pool*/,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken, uint256 i, uint256 j) = abi.decode(
            moreInfo,
            (address, address, uint256, uint256)
        );

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));

        SafeERC20.safeApprove(
            IERC20(fromToken),
            SMOOTHY,
            sellAmount
        );

        ISmoothyV1(SMOOTHY).swap(i, j, sellAmount, 0);

        require(IERC20(toToken).balanceOf(address(this)) > 0, 'not receive toToken');
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
        _swap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _swap(to, pool, moreInfo);
    }
}
