// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IPendle.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract PendleAdapter is IAdapter {

    address public immutable router;
    // empty limit order data, may result in price slippage
    LimitOrderData private emptyLimitOrderData; 

    constructor(address _router) {
        router = _router;
    }

    function _pendleSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken, bool isMint, bool isPT, bytes memory data) = abi.decode(
            moreInfo, 
            (address, address, bool, bool, bytes)
        );
        
        uint256 amountIn = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(fromToken),
            router,
            amountIn
        );
        // TokenInput and TokenOutput set as follows due to no aggregator involved here, refer to docs for more info
        if (isMint) {
            TokenInput memory input = TokenInput({
                tokenIn: fromToken,
                netTokenIn: amountIn,
                tokenMintSy: fromToken,
                pendleSwap: address(0),
                swapData: SwapData({
                    swapType: SwapType.NONE,
                    extRouter: address(0),
                    extCalldata: bytes(""),
                    needScale: false
                })
            });
            isPT ? _mintForPt(to, pool, input, data) : _mintForYt(to, pool, input, data);
        } else {
            TokenOutput memory output = TokenOutput({
                tokenOut: toToken,
                minTokenOut: 0,
                tokenRedeemSy: toToken,
                pendleSwap: address(0),
                swapData: SwapData({
                    swapType: SwapType.NONE,
                    extRouter: address(0),
                    extCalldata: bytes(""),
                    needScale: false
                })
            });
            isPT ? _redeemForPt(to, pool, amountIn, output) : _redeemForYt(to, pool, amountIn, output);
        }
    }

    function _mintForPt(address _to, address _pool, TokenInput memory _input, bytes memory _data) private {
        ApproxParams memory guessPtOut = abi.decode(_data, (ApproxParams));
        IPendle(router).swapExactTokenForPt(_to, _pool, 0, guessPtOut, _input, emptyLimitOrderData);
    }

    function _mintForYt(address _to, address _pool, TokenInput memory _input, bytes memory _data) private {
        ApproxParams memory guessYtOut = abi.decode(_data, (ApproxParams));
        IPendle(router).swapExactTokenForYt(_to, _pool, 0, guessYtOut, _input, emptyLimitOrderData);
    }

    function _redeemForPt(address _to, address _pool, uint256 _amountIn, TokenOutput memory _output) private {
        IPendle(router).swapExactPtForToken(_to, _pool, _amountIn, _output, emptyLimitOrderData);
    }

    function _redeemForYt(address _to, address _pool, uint256 _amountIn, TokenOutput memory _output) private {
        IPendle(router).swapExactYtForToken(_to, _pool, _amountIn, _output, emptyLimitOrderData);
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _pendleSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _pendleSwap(to, pool, moreInfo);
    }

}