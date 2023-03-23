// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISolidly.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

contract SolidlyAdapter is IAdapter {

    address public immutable ROUTER_ADDRESS;
    address public immutable WETH_ADDRESS;

    constructor(address _router, address _weth) {
        ROUTER_ADDRESS = _router;
        WETH_ADDRESS = _weth;
    }

    function _solidlySwap(
        address to,
        address,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken, bool isStable, uint256 amountOutMin, uint256 deadline) = abi.decode(
            moreInfo,
            (address,address, bool, uint256, uint256)
        );
        // get sellAmount
        uint256 sellAmount;
        // approve
        sellAmount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), ROUTER_ADDRESS, sellAmount);
        ISolidly.route[] memory path = new ISolidly.route[](1);
        path[0] = ISolidly.route(fromToken, toToken, isStable);
        ISolidly(ROUTER_ADDRESS).swapExactTokensForTokens(sellAmount,amountOutMin,path,address(this),deadline);
        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(toToken),
                to,
                IERC20(toToken).balanceOf(address(this))
            );
        }
//        (uint256 dnyFee, bool is_stable, address fromToken, address toToken, uint256 deadline, bool is_base) = abi.decode(
//            moreInfo,
//            (address, bool, bool)
//        );
//        if (is_stable) {
//
//        } else {
//            (uint256 reserveIn, uint256 reserveOut, ) = IUni(pool).getReserves();
//            require(
//                reserveIn > 0 && reserveOut > 0,
//                "DnyFeeAdapter: INSUFFICIENT_LIQUIDITY"
//            );
//            require(
//                dnyFee > 0 && dnyFee < 10000,
//                "DnyFeeAdapter: DNYFEE_MUST_BETWEEN_0_TO_10000"
//            );
//            if (is_base) {
//                address baseToken = IUni(pool).token0();
//                uint256 balance0 = IERC20(baseToken).balanceOf(pool);
//                uint256 sellBaseAmount = balance0 - reserveIn;
//
//                uint256 sellBaseAmountWithFee = sellBaseAmount * (10000 - dnyFee);
//                uint256 receiveQuoteAmount = sellBaseAmountWithFee * reserveOut / (reserveIn * 10000 + sellBaseAmountWithFee);
//                IUni(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
//            } else {
//                address quoteToken = IUni(pool).token1();
//                uint256 balance1 = IERC20(quoteToken).balanceOf(pool);
//                uint256 sellQuoteAmount = balance1 - reserveIn;
//
//                uint256 sellQuoteAmountWithFee = sellQuoteAmount * (10000 - dnyFee);
//                uint256 receiveBaseAmount = sellQuoteAmountWithFee * reserveOut / (reserveIn * 10000 + sellQuoteAmountWithFee);
//                IUni(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
//            }
//        }
    }

    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _solidlySwap(to, pool, moreInfo);
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _solidlySwap(to, pool, moreInfo);
    }

}