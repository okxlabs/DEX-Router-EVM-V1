// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./TokenApproveProxy.sol";

import "./interfaces/IBalancer.sol";
import "./interfaces/IBalancerV2Vault.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IWNativeRelayer.sol";

import "./libraries/CommonUtils.sol";
import "./libraries/EthReceiver.sol";
import "./libraries/RouterErrors.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/UniversalERC20.sol";

contract BalancerRouter is EthReceiver, CommonUtils {
    using UniversalERC20 for IERC20;

    address public constant VAULT_ADDRESS = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

//    function swapBalancerV1Pool(
//        bool unwrappedToToken,
//        address payable to,
//        address fromToken,
//        uint256 fromAmount,
//        uint256 minReturn,
//        bytes memory exchangeInfo
//    ) external payable {
//        // transfer fromToken from sender to CurveRouter
//        _prepareFromToken(fromToken, fromAmount);
//
//        // swap fromToken -> toToken via single pool
//        (address toToken, uint256 returnAmount) = _makeSwapBalancerV1(fromToken, fromAmount, exchangeInfo);
//
//        // transfer toToken to sender
//        _settleSwapResult(unwrappedToToken, to, toToken, returnAmount, minReturn);
//    }
//
//    function swapBalancerV2Pool(
//        bool unwrappedToToken,
//        address payable to,
//        address fromToken,
//        uint256 fromAmount,
//        uint256 minReturn,
//        bytes memory exchangeInfo
//    ) external payable {
//        // transfer fromToken from sender to CurveRouter
//        _prepareFromToken(fromToken, fromAmount);
//
//        // swap fromToken -> toToken via single pool
//        (address toToken, uint256 returnAmount) = _makeSwapBalancerV2(fromToken, fromAmount, exchangeInfo);
//
//        // transfer toToken to sender
//        _settleSwapResult(unwrappedToToken, to, toToken, returnAmount, minReturn);
//    }

    function swapBalancerV1Pools(
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
        _prepareFromToken(_token, _amount);

        // swap fromToken -> toToken via Curve pools
        for (uint256 i = 0; i < len; i++) {
            (_token, _amount)  = _makeSwapBalancerV1(_token, _amount, exchangeInfos[i]);
        }

        // transfer toToken to sender
        _settleBalancerSwapResult(unwrappedToToken, to, _token, _amount, minReturn);
    }

    function swapBalancerV2Pools(
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
        _prepareFromToken(_token, _amount);

        // swap fromToken -> toToken via Curve pools
        for (uint256 i = 0; i < len; i++) {
            (_token, _amount)  = _makeSwapBalancerV2(_token, _amount, exchangeInfos[i]);
        }

        // transfer toToken to sender
        _settleBalancerSwapResult(unwrappedToToken, to, _token, _amount, minReturn);
    }

    // transfer fromToken from sender to CurveRouter
    function _prepareFromToken(address fromToken, uint256 fromAmount) internal {
        if (msg.value > 0) {
            if (fromAmount != msg.value) revert RouterErrors.InvalidMsgValue();
            // eth -> weth
            if (fromToken != _WETH) revert RouterErrors.MsgValuedNotRequired();
            IWETH(_WETH).deposit{value: msg.value}();
        } else {
            IApproveProxy(_APPROVE_PROXY).claimTokens(fromToken, msg.sender, address(this), fromAmount);
        }
    }

    function _makeSwapBalancerV1(address fromToken, uint256 fromAmount, bytes memory exchangeInfo) internal returns (address, uint256) {
        // decode
        (address pool, address toToken) = abi.decode(exchangeInfo, (address, address));

        // approve erc20 [this -> pool]
        SafeERC20.safeApprove(IERC20(fromToken), pool, fromAmount);

        // swap
        uint256 returnAmount = IERC20(toToken).balanceOf(address(this));
        IBalancer(pool).swapExactAmountIn(fromToken, fromAmount, toToken, 0, type(uint256).max);

        // get returnAmount
        returnAmount = IERC20(toToken).balanceOf(address(this)) - returnAmount;

        // TODO: SafeERC20.safeApprove(IERC20(fromToken), pool, 0);
        return (toToken, returnAmount);
    }

    function _makeSwapBalancerV2(address fromToken, uint256 fromAmount, bytes memory exchangeInfo) internal returns (address, uint256) {
        // decode
        (bytes32 poolId, address toToken) = abi.decode(exchangeInfo, (bytes32, address));

        // make SingleSwap parameters
        IBalancerV2Vault.SingleSwap memory singleSwap;
        singleSwap.poolId = poolId;
        singleSwap.kind = IBalancerV2Vault.SwapKind.GIVEN_IN;
        singleSwap.assetIn = fromToken; // singleSwap.assetIn = fromToken == _ETH ? _WETH : fromToken;
        singleSwap.assetOut = toToken; //  singleSwap.assetOut = toToken == _ETH ? _WETH : toToken;
        singleSwap.amount = fromAmount;
        // make FundManagement parameters
        IBalancerV2Vault.FundManagement memory fund;
        fund.sender = address(this);
        fund.recipient = address(this);

        // approve erc20 [this -> pool]
        SafeERC20.safeApprove(IERC20(fromToken), VAULT_ADDRESS, fromAmount);

        // swap
        uint256 returnAmount = IERC20(toToken).balanceOf(address(this));
        IBalancerV2Vault(VAULT_ADDRESS).swap(singleSwap, fund, 0, block.timestamp);

        // get returnAmount
        returnAmount = IERC20(toToken).balanceOf(address(this)) - returnAmount;

        // TODO: SafeERC20.safeApprove(IERC20(fromToken), pool, 0);
        return (toToken, returnAmount);
    }

    function _settleBalancerSwapResult(bool unwrappedToToken, address payable to, address toToken, uint256 returnAmount, uint256 minReturn) internal {
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