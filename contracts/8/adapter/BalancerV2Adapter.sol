// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IBalancerV2Vault.sol";
import "../interfaces/IWETH.sol";

import "../libraries/SafeERC20.sol";

// for two tokens
contract BalancerV2Adapter is IAdapter {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable VAULT_ADDRESS;
    address public immutable WETH_ADDRESS;

    constructor(address _balancerVault, address _weth) {
        VAULT_ADDRESS = _balancerVault;
        WETH_ADDRESS = _weth;
    }

    function _balancerV2Swap(
        address to,
        address, /*vault*/
        bytes memory moreInfo
    ) internal {
        (address sourceToken, address targetToken, bytes32 poolId) = abi.decode(
            moreInfo,
            (address, address, bytes32)
        );

        // fromToken ！= targetToken, The Balancer Vault will check
        // In balancer eth or weth are exchanged for other tokens using the same pool,
        // The dex router will only transfer weth here
        uint256 sellAmount = 0;
        if (sourceToken == ETH_ADDRESS) {
            sellAmount = IWETH(WETH_ADDRESS).balanceOf(address(this));
        } else {
            sellAmount = IERC20(sourceToken).balanceOf(address(this));
        }

        IBalancerV2Vault.SingleSwap memory singleSwap;
        singleSwap.poolId = poolId;
        singleSwap.kind = IBalancerV2Vault.SwapKind.GIVEN_IN;
        singleSwap.assetIn = sourceToken == ETH_ADDRESS
            ? WETH_ADDRESS
            : sourceToken;
        singleSwap.assetOut = targetToken == ETH_ADDRESS
            ? WETH_ADDRESS
            : targetToken;
        singleSwap.amount = sellAmount;

        IBalancerV2Vault.FundManagement memory fund;
        fund.sender = address(this);
        fund.recipient = to;

        // approve
        SafeERC20.safeApprove(
            IERC20(sourceToken == ETH_ADDRESS ? WETH_ADDRESS : sourceToken),
            VAULT_ADDRESS,
            sellAmount
        );
        // swap, the limit parameter is 0 for the time being, and the slippage point is not considered for the time being
        IBalancerV2Vault(VAULT_ADDRESS).swap(
            singleSwap,
            fund,
            0,
            block.timestamp
        );
        
    }

    function sellBase(
        address to,
        address vault,
        bytes memory moreInfo
    ) external override {
        _balancerV2Swap(to, vault, moreInfo);
    }

    function sellQuote(
        address to,
        address vault,
        bytes memory moreInfo
    ) external override {
        _balancerV2Swap(to, vault, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}
