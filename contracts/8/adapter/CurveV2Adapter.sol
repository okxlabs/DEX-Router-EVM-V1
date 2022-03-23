

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ICurveV2.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "hardhat/console.sol";

// for two tokens
contract CurveV2Adapter is IAdapter {
    struct CurveDataV2 {
        address fromToken;
        address toToken;
        int128 fromCoinIdx;
        int128 toCoinIdx;
        bytes4 exchangeFunctionSelector;
    }

    function _curveSwap(address to, address pool, bytes memory moreInfo) internal {
        CurveDataV2 memory data = abi.decode(moreInfo, (CurveDataV2));
        require(data.fromToken == ICurveV2(pool).underlying_coins(data.fromCoinIdx), "CurveV2Adapter: WRONG_TOKEN");
        require(data.toToken == ICurveV2(pool).underlying_coins(data.toCoinIdx), "CurveV2Adapter: WRONG_TOKEN");
    

        uint256 sellAmount = IERC20(data.fromToken).balanceOf(address(this));
        // approve
        IERC20(data.fromToken).approve(pool, sellAmount);

        // swap
        // ICurve(pool).exchange_underlying(data.fromCoinIdx, data.toCoinIdx, sellAmount, 0);
        (bool _success, bytes memory _resultData) =
            pool.call(abi.encodeWithSelector(
                data.exchangeFunctionSelector,
                data.fromCoinIdx,
                data.toCoinIdx,
                // dx
                sellAmount,
                // min dy
                1
            ));

        if(to != address(this) && _success) {
            SafeERC20.safeTransfer(IERC20(data.toToken), to, IERC20(data.toToken).balanceOf(address(this)));
        }
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _curveSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _curveSwap(to, pool, moreInfo);
    }
}