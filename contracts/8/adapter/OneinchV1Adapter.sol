// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOneinch} from "../interfaces/IOneinch.sol";
import {IAdapter} from "../interfaces/IAdapter.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

contract OneinchV1Adapter is IAdapter {
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private immutable WETH;

    constructor(address _weth) {
        WETH = _weth;
    }

    function _oneinchSwap(address to, address pool, bytes memory moreInfo) internal {
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

        IOneinch(pool).swapFor(fromToken, toToken, amount, 0, address(0), to);
    }

    function _handleSwapFromETH(address to, address pool, address, address toToken) internal {
        uint256 amount = IERC20(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amount);
        /// for the pool: https://etherscan.io/address/0x6a11f3e5a01d129e566d783a7b6e8862bfd66cca#readContract
        /// it is an ETH_WBTC pool, where token0 is address(0) to represent the ETH
        IOneinch(pool).swapFor{value: amount}(address(0), toToken, amount, 0, address(0), to);
    }

    function _handleSwapToETH(address to, address pool, address fromToken, address) internal {
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, amount);
        /// for the pool: https://etherscan.io/address/0x6a11f3e5a01d129e566d783a7b6e8862bfd66cca#readContract
        /// it is the ETH_WBTC, since the adapter needs to WETH in and WETH out, so if it is ETH, we need to wrap it into WETH and send out.
        /// so the receive address must be address(this)
        IOneinch(pool).swapFor(fromToken, address(0), amount, 0, address(0), address(this));
        // for the multihop, WBTC->ETH->USDC, it all happens in this adapter
        // i change the if condition from to!=address(this), because the _exeFork always set the to address to router, not the adapter.
        // so under that condition will always be true.
        uint256 amountOut = address(this).balance;
        if (amountOut > 0) {
            IWETH(WETH).deposit{value: amountOut}();
            IWETH(WETH).transfer(to, amountOut);
        }
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _oneinchSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _oneinchSwap(to, pool, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
