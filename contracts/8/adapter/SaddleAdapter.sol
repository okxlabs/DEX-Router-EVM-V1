// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISaddle.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract SaddleAdapter is IAdapter {
    function _saddleSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (
            address fromToken,
            address toToken,
            uint8 tokenIndexFrom,
            uint8 tokenIndexTo,
            uint256 deadline,
            bool is_underlying
        ) = abi.decode(moreInfo, (address, address, uint8, uint8, uint256, bool));
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        // approve
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);

        // swap
        if (is_underlying) {
            IMetaSwap(pool).swap(tokenIndexFrom, tokenIndexTo, sellAmount, 0, deadline);
        } else {
            ISwap(pool).swap(tokenIndexFrom, tokenIndexTo, sellAmount, 0, deadline);
        }

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
        _saddleSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _saddleSwap(to, pool, moreInfo);
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
    }
}
