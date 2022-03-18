// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IBalancerV2Vault.sol";

import "../libraries/SafeERC20.sol";

// for two tokens
contract BalancerV2Adapter is IAdapter {

    function _balancerV2Swap(address to, address vault, bytes memory moreInfo) internal {
        (address fromToken, address toToken, bytes32 poolId) = abi.decode(moreInfo, (address, address, bytes32));

        // fromToken ！= toToken, The Balancer Vault will check

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        IBalancerV2Vault.SingleSwap memory singleSwap;
        singleSwap.poolId = poolId;
        singleSwap.kind = IBalancerV2Vault.SwapKind.GIVEN_IN;
        singleSwap.assetIn = fromToken;
        singleSwap.assetOut = toToken;
        singleSwap.amount = sellAmount;

        IBalancerV2Vault.FundManagement memory fund;
        fund.sender = address(this);
        fund.recipient = to;

        // approve sell amount
        SafeERC20.safeApprove(IERC20(fromToken), vault, sellAmount);
        // swap, the limit parameter is 0 for the time being, and the slippage point is not considered for the time being
        IBalancerV2Vault(vault).swap(singleSwap, fund, 0, block.timestamp + 30 seconds);
        // approve 0
        SafeERC20.safeApprove(IERC20(fromToken), vault, 0);
    }

    function sellBase(address to, address vault, bytes memory moreInfo) external override {
        _balancerV2Swap(to, vault, moreInfo);
    }

    function sellQuote(address to, address vault, bytes memory moreInfo) external override {
        _balancerV2Swap(to, vault, moreInfo);
    }
}