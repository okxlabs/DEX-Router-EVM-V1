// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISynapse.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract SynapseAdapter is IAdapter {

    function _synapseSwap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken, uint256 deadline) = abi.decode(moreInfo, (address, address, uint256));
        uint8 fromTokenIndex = ISynapse(pool).getTokenIndex(fromToken);
        uint8 toTokenIndex = ISynapse(pool).getTokenIndex(toToken);
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        // approve
        SafeERC20.safeApprove(IERC20(fromToken),  pool, sellAmount);

        // swap
        ISynapse(pool).swap(fromTokenIndex, toTokenIndex, sellAmount, 0, deadline);

        if(to != address(this)) {
            SafeERC20.safeTransfer(IERC20(toToken), to, IERC20(toToken).balanceOf(address(this)));
        }
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _synapseSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _synapseSwap(to, pool, moreInfo);
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
    }
}