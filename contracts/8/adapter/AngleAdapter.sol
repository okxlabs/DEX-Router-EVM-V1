// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ITransmuter.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract AngleAdapter is IAdapter {

    function _AngleSwap(
        address to,
        address pool,        
        bytes memory moreInfo
    ) internal {
        (address tokenIn, address tokenOut) = abi.decode(moreInfo, (address, address));
        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(tokenIn), pool, amountIn);
        ITransmuter(pool).swapExactInput(amountIn, 0, tokenIn, tokenOut, to, block.timestamp);
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _AngleSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _AngleSwap(to, pool, moreInfo);
    }

}