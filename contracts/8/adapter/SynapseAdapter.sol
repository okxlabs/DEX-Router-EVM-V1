// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISynapse.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ILendingPool.sol";

import "../libraries/SafeERC20.sol";

contract SynapseAdapter is IAdapter {
    address constant WETH_e = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
    address constant avETH = 0x53f7c5869a859F0AeC3D334ee8B4Cf01E3492f21;
    address constant avETH_nETH = 0x77a7e60555bC18B4Be44C181b2575eee46212d44;
    address constant aaveLendingPoolV2 =
        0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;
    uint256 constant AVAX_CCHAIN_ID = 43114;

    function _synapseSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken, uint256 deadline) = abi.decode(
            moreInfo,
            (address, address, uint256)
        );
        if (
            block.chainid == AVAX_CCHAIN_ID &&
            (fromToken == WETH_e || toToken == WETH_e)
        ) {
            _handleEdgeCaseOnAvax(to, pool, moreInfo);
            return;
        }

        uint256 amountOut = _internalSwap(fromToken, toToken, pool, deadline);

        if (to != address(this)) {
            SafeERC20.safeTransfer(IERC20(toToken), to, amountOut);
        }
    }

    function _internalSwap(
        address fromToken,
        address toToken,
        address pool,
        uint256 deadline
    ) internal returns (uint256 amountOut) {
        uint8 fromTokenIndex = ISynapse(pool).getTokenIndex(fromToken);
        uint8 toTokenIndex = ISynapse(pool).getTokenIndex(toToken);
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        // approve
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);

        // swap
        amountOut = ISynapse(pool).swap(
            fromTokenIndex,
            toTokenIndex,
            sellAmount,
            0,
            deadline
        );
    }

    function _handleEdgeCaseOnAvax(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        require(pool == avETH_nETH, "pool address misconfigured");
        (address fromToken, address toToken, uint256 deadline) = abi.decode(
            moreInfo,
            (address, address, uint256)
        );
        if (fromToken == WETH_e) {
            uint amountIn = IERC20(WETH_e).balanceOf(address(this));
            IERC20(WETH_e).approve(aaveLendingPoolV2, amountIn);
            ILendingPool(aaveLendingPoolV2).deposit(WETH_e, amountIn, address(this), 0);
            uint256 amountOut = _internalSwap(avETH, toToken, pool, deadline);
            if (to != address(this)) {
                SafeERC20.safeTransfer(IERC20(toToken), to, amountOut);
            }
        } else if (toToken == WETH_e) {
            uint256 amountOut = _internalSwap(fromToken, avETH, pool, deadline);
            ILendingPool(aaveLendingPoolV2).withdraw(WETH_e, amountOut, to);
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _synapseSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _synapseSwap(to, pool, moreInfo);
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
    }
}
