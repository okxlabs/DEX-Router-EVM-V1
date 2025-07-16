// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/IAdapter.sol";
import "../interfaces/IArbStableSwap.sol";
import "../interfaces/IArbswapV2Exchange.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract ArbSwapV2Adapter is IAdapter {
    using Math for uint256;

    enum FLAG {
        STABLE_SWAP,
        V2_EXACT_IN
    }

    // fromToken == token0
    function sellBase(
        address receipt,
        address exchange,
        bytes memory moreInfo
    ) external override {
        (FLAG flag, bytes memory info) = abi.decode(moreInfo, (FLAG, bytes));
        if (flag == FLAG.STABLE_SWAP) {
            _swapOnStableSwap(receipt, IArbStableSwap(exchange), info);
        } else if (flag == FLAG.V2_EXACT_IN) {
            address baseToken = IArbswapV2Exchange(exchange).token0();
            address quoteToken = IArbswapV2Exchange(exchange).token1();
            uint256 amountIn = IERC20(baseToken).balanceOf(address(this));
            _swapOnV2ExactIn(
                receipt,
                IArbswapV2Exchange(exchange),
                baseToken,
                quoteToken,
                amountIn
            );
        }
    }

    // fromToken == token1
    function sellQuote(
        address receipt,
        address exchange,
        bytes memory moreInfo
    ) external override {
        (FLAG flag, bytes memory info) = abi.decode(moreInfo, (FLAG, bytes));
        if (flag == FLAG.STABLE_SWAP) {
            _swapOnStableSwap(receipt, IArbStableSwap(exchange), info);
        } else if (flag == FLAG.V2_EXACT_IN) {
            address baseToken = IArbswapV2Exchange(exchange).token0();
            address quoteToken = IArbswapV2Exchange(exchange).token1();
            uint256 amountIn = IERC20(quoteToken).balanceOf(address(this));
            _swapOnV2ExactIn(
                receipt,
                IArbswapV2Exchange(exchange),
                quoteToken,
                baseToken,
                amountIn
            );
        }
    }

    function _swapOnStableSwap(
        address receipt,
        IArbStableSwap stableSwap,
        bytes memory info
    ) internal {
        (address srcToken, address dstToken, uint256 i, uint256 j) = abi.decode(
            info,
            (address, address, uint256, uint256)
        );

        // approve
        uint256 amount = IERC20(srcToken).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(srcToken),
            address(stableSwap),
            amount
        );

        // swap
        stableSwap.exchange(i, j, amount, 0);

        // transfer dstToken to receipt
        SafeERC20.safeTransfer(
            IERC20(dstToken),
            receipt,
            IERC20(dstToken).balanceOf(address(this))
        );
    }

    function _swapOnV2ExactIn(
        address receipt,
        IArbswapV2Exchange exchange,
        address srcToken,
        address dstToken,
        uint256 amountIn
    ) internal returns (uint256 returnAmount) {
        SafeERC20.safeTransfer(IERC20(srcToken), address(exchange), amountIn);
        bool needSync;
        (returnAmount, needSync) = getReturn(
            exchange,
            srcToken,
            dstToken,
            amountIn
        );
        if (needSync) {
            exchange.sync();
        }
        if (srcToken < dstToken) {
            exchange.swap(0, returnAmount, receipt, "");
        } else {
            exchange.swap(returnAmount, 0, receipt, "");
        }
    }

    function getReturn(
        IArbswapV2Exchange exchange,
        address srcToken,
        address dstToken,
        uint256 amountIn
    ) internal view returns (uint256 result, bool needSync) {
        uint256 reserveIn = IERC20(srcToken).balanceOf(address(exchange));
        uint256 reserveOut = IERC20(dstToken).balanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1, ) = exchange.getReserves();
        if (srcToken > dstToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        amountIn = reserveIn - reserve0;
        needSync = (reserveIn < reserve0 || reserveOut < reserve1);

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * Math.min(reserveOut, reserve1);
        uint256 denominator = Math.min(reserveIn, reserve0) *
            1000 +
            amountInWithFee;
        result = (denominator == 0) ? 0 : numerator / denominator;
    }
}
