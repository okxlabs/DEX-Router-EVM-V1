// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/SafeERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/ISovereignPool.sol";

contract SovereignPoolAdapter is IAdapter {
    function _sovereign_swap(
        address to,
        address pool,
        bytes memory moreInfo
    ) private {
        (address tokenIn, address tokenOut) = abi.decode(
            moreInfo,
            (address, address)
        );

        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(tokenIn), pool, amountIn);

        ISovereignPool.SovereignPoolSwapParams memory params;
        params.isSwapCallback = false;
        params.isZeroToOne = tokenIn == ISovereignPool(pool).token0();
        params.amountIn = amountIn;
        params.amountOutMin = 0;
        params.deadline = block.timestamp;
        params.recipient = to;
        params.swapTokenOut = tokenOut;

        ISovereignPool(pool).swap(params);
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _sovereign_swap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _sovereign_swap(to, pool, moreInfo);
    }
}
