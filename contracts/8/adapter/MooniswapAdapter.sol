// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMooniswap} from "../interfaces/IMooniswap.sol";
import {IAdapter} from "../interfaces/IAdapter.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

contract MooniswapAdapter is IAdapter {
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private immutable WETH;

    constructor(address _weth) {
        WETH = _weth;
    }

    function _MooniswapSwap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));
        if (fromToken == ETH_ADDRESS) {
            _handleSwapFromETH(to, pool, fromToken, toToken);
            return;
        } else if (toToken == ETH_ADDRESS) {
            _handleSwapToETH(to, pool, fromToken, toToken);
            return;
        } else {
            _handleSwap(to, pool, fromToken, toToken);
            return;
        }
    }

    function _handleSwap(address to, address pool, address fromToken, address toToken) internal {
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, amount);

        uint256 amountRes = IMooniswap(pool).swap(fromToken, toToken, amount, 0, address(0));
        if (to != address(this)) {
            SafeERC20.safeTransfer(IERC20(toToken), to, amountRes);
        }
    }

    function _handleSwapFromETH(address to, address pool, address, address toToken) internal {
        uint256 amount = IERC20(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amount);

        uint256 amountRes = IMooniswap(pool).swap{value: amount}(address(0), toToken, amount, 0, address(0));
        if (to != address(this)) {
            SafeERC20.safeTransfer(IERC20(toToken), to, amountRes);
        }
    }

    function _handleSwapToETH(address to, address pool, address fromToken, address) internal {
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, amount);

        IMooniswap(pool).swap(fromToken, address(0), amount, 0, address(0));
        uint256 amountOut = address(this).balance;
        if (amountOut > 0) {
            IWETH(WETH).deposit{value: amountOut}();
            IWETH(WETH).transfer(to, amountOut);
        }
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _MooniswapSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _MooniswapSwap(to, pool, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
