// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IMstable.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract MstableAdapter is IAdapter {
    function _mstableSwap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));

        if (toToken == pool) {
            _handleMint(to, pool, fromToken, toToken);
            return;
        } else if (fromToken == pool) {
            _handleRedeem(to, pool, fromToken, toToken);
            return;
        } else {
            _handleSwap(to, pool, fromToken, toToken);
            return;
        }
    }

    function _handleSwap(address to, address pool, address fromToken, address toToken)
        internal
    {
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, amount);
        IMstable(pool).swap(fromToken, toToken, amount, 0, to);
    }

    function _handleMint(address to, address pool, address fromToken, address toToken)
        internal
    {
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, amount);
        IMstable(pool).mint(fromToken, amount, 0, to);
    }

    function _handleRedeem(address to, address pool, address fromToken, address toToken)
        internal
    {
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        IMstable(pool).redeem(toToken, amount, 0, to);
    }

    function sellBase(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _mstableSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _mstableSwap(to, pool, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}
