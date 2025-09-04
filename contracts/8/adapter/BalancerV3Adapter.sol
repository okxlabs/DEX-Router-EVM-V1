// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IAdapter.sol";
import "../interfaces/IBalancerV3Vault.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";


// The BalancerV3 Vault does not support ETH and dexRouter will wrap to WETH if fromToken is ETH,
// so this adapter does not receive ETH and only consider that fromToken is ERC20 (including WETH).
contract BalancerV3Adapter is IAdapter {

    address public immutable VAULT_ADDRESS;

    error OnlyVault();
    error InsufficientCreditReceived();

    constructor(address _balancerVault) {
        VAULT_ADDRESS = _balancerVault;
    }

    modifier onlyVault() {
        if (msg.sender != VAULT_ADDRESS) {
            revert OnlyVault();
        }
        _;
    }

    function balancerV3Swap(
        address to,
        address pool,
        bytes memory moreInfo
    ) external onlyVault() {
        (address fromToken, address toToken) = abi.decode(
            moreInfo,
            (address, address)
        );
        // The BalancerV3 Vault will ensure that fromToken != toToken.

        uint256 amountIn = IERC20(fromToken).balanceOf(address(this));

        // transfer fromToken to Vault and settle.
        SafeERC20.safeTransfer(IERC20(fromToken), VAULT_ADDRESS, amountIn);
        uint256 credit = IBalancerV3Vault(VAULT_ADDRESS).settle(IERC20(fromToken), amountIn);
        if (credit != amountIn) {
            revert InsufficientCreditReceived();
        }
        
        // swap
        IBalancerV3Vault.VaultSwapParams memory params = IBalancerV3Vault.VaultSwapParams({
            pool: pool,
            tokenIn: IERC20(fromToken),
            tokenOut: IERC20(toToken),
            amountGivenRaw: amountIn,
            kind: IBalancerV3Vault.SwapKind.EXACT_IN,
            limitRaw: 0,
            userData: ""
        });
        (,, uint256 amountOutRaw) = IBalancerV3Vault(VAULT_ADDRESS).swap(params);

        // send toToken to to address
        IBalancerV3Vault(VAULT_ADDRESS).sendTo(IERC20(toToken), to, amountOutRaw);
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        IBalancerV3Vault(VAULT_ADDRESS).unlock(
            abi.encodeCall(
                BalancerV3Adapter.balancerV3Swap,
                (to, pool, moreInfo)
            )
        );
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        IBalancerV3Vault(VAULT_ADDRESS).unlock(
            abi.encodeCall(
                BalancerV3Adapter.balancerV3Swap,
                (to, pool, moreInfo)
            )
        );
    }
}
