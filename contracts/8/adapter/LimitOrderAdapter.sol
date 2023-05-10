// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ILimitOrder.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract LimitOrderAdapter is IAdapter {

    address public immutable AggV5_ADDRESS;

    constructor(address _agg_v5) {
        AggV5_ADDRESS = _agg_v5;
    }


    function _limitOrderSwap(
        address to,
        address,
        bytes memory moreInfo
    ) internal {
        (IOrder memory order, bytes memory signature, uint256 skipPermitAndThresholdAmount,uint256 realMakingAmount) = abi.decode(moreInfo, (IOrder, bytes, uint256, uint256));
        address fromToken = order.takerAsset;
        address toToken = order.makerAsset;
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), AggV5_ADDRESS, sellAmount);
        ILimitOrder(AggV5_ADDRESS).fillOrderTo(order, signature, new bytes(0), 0, sellAmount, skipPermitAndThresholdAmount, address(this));

        // approve 0
        SafeERC20.safeApprove(
            IERC20(fromToken),
            AggV5_ADDRESS,
            0
        );
        require(IERC20(toToken).balanceOf(address(this)) >= realMakingAmount, "LimitOrderAdapter: not reach min out");
        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(toToken),
                to,
                IERC20(toToken).balanceOf(address(this))
            );
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _limitOrderSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _limitOrderSwap(to, pool, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }

}
