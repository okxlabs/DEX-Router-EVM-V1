// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEchodex, IEchodexFactory} from "../interfaces/IEchodex.sol";
import {IAdapter} from "../interfaces/IAdapter.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

contract EchodexAdapter is IAdapter {
    address private immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function _Echoswap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));
        address feeToken = IEchodexFactory(factory).tokenFee();
        address token0 = IEchodex(pool).token0();
        if (fromToken == feeToken) {
            _handlePreTax(to, pool, fromToken, toToken, fromToken == token0);
            return;
        } else {
            _handleSwap(to, pool, fromToken, toToken, fromToken == token0);
            return;
        }
    }
    //会多算一点手续费,但是也在可接受范围内. 很难准确的算出来

    function _handlePreTax(address to, address pool, address fromToken, address toToken, bool isToken0) internal {
        uint256 amountIn = IERC20(fromToken).balanceOf(address(this));
        uint256 amountOut = getAmountOut(amountIn, isToken0, pool, 0);
        uint256 fee = IEchodexFactory(factory).calcFeeOrReward(toToken, amountOut, 10);
        SafeERC20.safeApprove(IERC20(fromToken), pool, fee);
        IEchodex(pool).addFee(fee);
        amountIn = amountIn - fee;
        amountOut = getAmountOut(amountIn, isToken0, pool, 0);
        (uint256 amount0Out, uint256 amount1Out) = isToken0 ? (uint256(0), amountOut) : (amountOut, 0);
        SafeERC20.safeTransfer(IERC20(fromToken), pool, amountIn);
        IEchodex(pool).swapPayWithTokenFee(amount0Out, amount1Out, to, "");
    }

    function _handleSwap(address to, address pool, address fromToken, address toToken, bool isToken0) internal {
        uint256 amountIn = IERC20(fromToken).balanceOf(address(this));
        uint256 amountOut = getAmountOut(amountIn, isToken0, pool, 3);
        (uint256 amount0Out, uint256 amount1Out) = isToken0 ? (uint256(0), amountOut) : (amountOut, 0);
        SafeERC20.safeTransfer(IERC20(fromToken), pool, amountIn);
        IEchodex(pool).swap(amount0Out, amount1Out, to, "");
    }

    function getAmountOut(uint256 amountIn, bool isToken0, address pool, uint256 fee)
        internal
        view
        returns (uint256 amountOut)
    {
        (uint256 r0, uint256 r1,) = IEchodex(pool).getReserves();
        (uint256 rIn, uint256 rOut) = isToken0 ? (r0, r1) : (r1, r0);
        uint256 numerator = amountIn * rOut;
        uint256 denominator = rIn + amountIn;
        amountOut = numerator / denominator;

        amountOut = amountOut * (1000 - fee) / 1000;
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _Echoswap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _Echoswap(to, pool, moreInfo);
    }
}
