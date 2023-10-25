// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDODOV3} from "../interfaces/IDODOV3.sol";
import {IAdapter} from "../interfaces/IAdapter.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "../interfaces/IDODOSwapCallback.sol";
import "../libraries/SafeERC20.sol";

contract DODOV3Adapter is IAdapter, IDODOSwapCallback {

    function _dodoV3Swap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken) = abi.decode(
            moreInfo,
            (address, address)
        );
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        // neglect minReceiveAmount to 0 here
        IDODOV3(pool).sellToken(to, fromToken, toToken, sellAmount, 0, "");
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _dodoV3Swap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _dodoV3Swap(to, pool, moreInfo);
    }

    function d3MMSwapCallBack(
        address token,
        uint256 value,
        bytes calldata data
    ) external override {
        require(value > 0, "wrong liquidity");
        SafeERC20.safeTransfer(IERC20(token), msg.sender, value);
    }

}