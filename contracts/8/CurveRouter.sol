// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./TokenApproveProxy.sol";

import "./interfaces/ICurve.sol";
import "./interfaces/ICurveV2.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IWNativeRelayer.sol";

import "./libraries/CommonUtils.sol";
import "./libraries/EthReceiver.sol";
import "./libraries/RouterErrors.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/UniversalERC20.sol";

contract CurveRouter is EthReceiver, CommonUtils {
    using UniversalERC20 for IERC20;

//    function swapCurveV1Pool(
//        bool unwrappedToToken,
//        address payable to,
//        address fromToken,
//        uint256 fromAmount,
//        uint256 minReturn,
//        bytes memory exchangeInfo
//    ) external payable {
//        // transfer fromToken from sender to CurveRouter
//        _prepareFromToken(fromToken, fromAmount, false);
//
//        // swap fromToken -> toToken via single pool
//        (address toToken, uint256 returnAmount) = _makeSwapCurveV1(fromToken, fromAmount, exchangeInfo);
//
//        // unwrapped toToken
//        if (unwrappedToToken && toToken == _WETH) {
//            IWETH(_WETH).transfer(_WNATIVE_RELAY, returnAmount);
//            IWNativeRelayer(_WNATIVE_RELAY).withdraw(returnAmount);
//            toToken = _ETH;
//        }
//        // transfer toToken to sender
//        _settleSwapResult(to, toToken, returnAmount, minReturn);
//    }
//
//    function swapCurveV2Pool(
//        bool wrappedToToken,
//        address payable to,
//        address fromToken,
//        uint256 fromAmount,
//        uint256 minReturn,
//        bytes memory exchangeInfo
//    ) external payable {
//        // transfer fromToken from sender to CurveRouter
//        _prepareFromToken(fromToken, fromAmount, true);
//
//        // swap fromToken -> toToken via single pool
//        (address toToken, uint256 returnAmount) = _makeSwapCurveV2(fromToken, fromAmount, exchangeInfo);
//
//        // wrapped toToken
//        if (wrappedToToken && toToken == _ETH) {
//            IWETH(_WETH).deposit{value: returnAmount}();
//            toToken = _WETH;
//        }
//        // transfer toToken to sender
//        _settleSwapResult(to, toToken, returnAmount, minReturn);
//    }

    function swapCurveV1Pools(
        bool unwrappedToToken,
        address payable to,
        address _token,  // fromToken
        uint256 _amount, // fromAmount
        uint256 minReturn,
        bytes[] memory exchangeInfos
    ) external payable {
        uint256 len = exchangeInfos.length;
        if (len == 0) revert RouterErrors.EmptyPools();

        // transfer fromToken from sender to CurveRouter
        _prepareFromToken(_token, _amount, false);

        // swap fromToken -> toToken via Curve pools
        for (uint256 i = 0; i < len; i++) {
            (_token, _amount)  = _makeSwapCurveV1(_token, _amount, exchangeInfos[i]);
        }

        // transfer toToken to sender
        _settleCurveResult(unwrappedToToken, to, _token, _amount, minReturn);
    }

    function swapCurveV2Pools(
        bool unwrappedToToken,
        address payable to,
        address _token,  // fromToken
        uint256 _amount, // fromAmount
        uint256 minReturn,
        bytes[] memory exchangeInfos
    ) external payable {
        uint256 len = exchangeInfos.length;
        if (len == 0) revert RouterErrors.EmptyPools();

        // transfer fromToken from sender to CurveRouter
        _prepareFromToken(_token, _amount, true);

        // swap fromToken -> toToken via Curve pools
        for (uint256 i = 0; i < len; i++) {
            (_token, _amount)  = _makeSwapCurveV2(_token, _amount, exchangeInfos[i]);
        }

        // transfer toToken to sender
        _settleCurveResult(unwrappedToToken, to, _token, _amount, minReturn);
    }

    // transfer fromToken from sender to CurveRouter
    function _prepareFromToken(address fromToken, uint256 fromAmount, bool v2) internal {
        if (msg.value > 0) {
            if (fromAmount != msg.value) revert RouterErrors.InvalidMsgValue();

            if (v2) {
                // curveV2: remain eth
                if (fromToken != _ETH) revert RouterErrors.MsgValuedNotRequired();
            } else {
                // curveV1: eth -> weth
                if (fromToken != _WETH) revert RouterErrors.MsgValuedNotRequired();
                IWETH(_WETH).deposit{value: msg.value}();
            }
        } else {
            IApproveProxy(_APPROVE_PROXY).claimTokens(fromToken, msg.sender, address(this), fromAmount);
        }
    }

    function _makeSwapCurveV1(address fromToken, uint256 fromAmount, bytes memory exchangeInfo) internal returns (address, uint256) {
        // decode
        (address pool, address toToken, int128 i, int128 j, bool is_underlying) = abi.decode(exchangeInfo, (address, address, int128, int128, bool));

        // approve erc20 [this -> pool]
        SafeERC20.safeApprove(IERC20(fromToken), pool, fromAmount);
        // swap
        uint256 returnAmount = IERC20(toToken).balanceOf(address(this));
        if (is_underlying) {
            ICurve(pool).exchange_underlying(i, j, fromAmount, 0);
        } else {
            ICurve(pool).exchange(i, j, fromAmount, 0);
        }

        // get returnAmount
        returnAmount = IERC20(toToken).balanceOf(address(this)) - returnAmount;

        // TODO: SafeERC20.safeApprove(IERC20(fromToken), pool, 0);
        return (toToken, returnAmount);
    }

    function _makeSwapCurveV2(address fromToken, uint256 fromAmount, bytes memory exchangeInfo) internal returns (address, uint256) {
        // decode
        (address pool, address toToken, uint256 i, uint256 j) = abi.decode(exchangeInfo, (address, address, uint256, uint256));

        // swap
        uint256 returnAmount = IERC20(toToken).universalBalanceOf(address(this));
        if (fromToken == _ETH) {
            ICurveV2(pool).exchange{value: fromAmount}(i, j, fromAmount, 0, true);
        } else {
            // approve erc20 [this -> pool]
            SafeERC20.safeApprove(IERC20(fromToken), pool, fromAmount);
            ICurveV2(pool).exchange(i, j, fromAmount, 0);
        }

        // get returnAmount
        returnAmount = IERC20(toToken).universalBalanceOf(address(this)) - returnAmount;

        // TODO: SafeERC20.safeApprove(IERC20(fromToken), pool, 0);
        return (toToken, returnAmount);
    }

    function _settleCurveResult(bool unwrappedToToken, address payable to, address toToken, uint256 returnAmount, uint256 minReturn) internal {
        // check minReturn
        if (returnAmount <= minReturn) revert RouterErrors.ReturnAmountIsNotEnough();

        // unwrapped toToken
        if (unwrappedToToken && toToken == _WETH) {
            IWETH(_WETH).transfer(_WNATIVE_RELAY, returnAmount);
            IWNativeRelayer(_WNATIVE_RELAY).withdraw(returnAmount);
            toToken = _ETH;
        }

        // transfer
        if (to != address(this)) {
            IERC20(toToken).universalTransfer(to, returnAmount);
        }
    }
}