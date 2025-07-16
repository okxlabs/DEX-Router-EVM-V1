// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IIron.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ILendingPool.sol";

import "../libraries/SafeERC20.sol";

contract IronswapAdapter is IAdapter {
    function _ironSwap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));

        uint256 amountOut = _internalSwap(fromToken, toToken, pool);

        if (to != address(this)) {
            SafeERC20.safeTransfer(IERC20(toToken), to, amountOut);
        }
    }

    function _internalSwap(address fromToken, address toToken, address pool)
        internal
        returns (uint256 amountOut)
    {
        uint8 fromTokenIndex = IIron(pool).getTokenIndex(fromToken);
        uint8 toTokenIndex = IIron(pool).getTokenIndex(toToken);
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        // approve
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);

        // swap
        amountOut =
            IIron(pool).swap(fromTokenIndex, toTokenIndex, sellAmount, 0, block.timestamp);
    }

    function sellBase(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _ironSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _ironSwap(to, pool, moreInfo);
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
    }
}
