// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IBalancerV2Composable.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";


contract BalancerV2ComposableAdapter is IAdapter {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable VAULT_ADDRESS;
    
    uint8 constant TWO = 2;
    uint8 constant THREE = 3;
    uint8 constant FOUR = 4;

    constructor (
        address _balancerVault
    ) {
        VAULT_ADDRESS = _balancerVault;
    }

    // GAS: 306923
    function _balanverV2ComposableSwapTripleHop(
        address to,
        bytes memory moreInfo
    ) internal {
        (Hop memory firstHop, Hop memory secondHop, Hop memory threeHop) = abi.decode(moreInfo, (Hop,Hop,Hop) );

        // init swaps
        IBalancerV2Vault.BatchSwapStep[] memory swaps = new IBalancerV2Vault.BatchSwapStep[](THREE);
        swaps[0] = IBalancerV2Vault.BatchSwapStep({
            poolId: firstHop.poolId,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: IERC20(firstHop.sourceToken).balanceOf(address(this)),
            userData: bytes("")
        });

        swaps[1] = IBalancerV2Vault.BatchSwapStep({
            poolId: secondHop.poolId,
            assetInIndex: 1,
            assetOutIndex: 2,
            amount: 0, // depend on the actual amount
            userData: bytes("")
        });

        swaps[2] = IBalancerV2Vault.BatchSwapStep({
            poolId: threeHop.poolId,
            assetInIndex: 2,
            assetOutIndex: 3,
            amount: 0, // depend on the actual amount
            userData: bytes("")
        });

        // init assets: max in or min out
        IAsset[] memory assets = new IAsset[](FOUR);
        assets[0] = IAsset(firstHop.sourceToken);
        assets[1] = IAsset(secondHop.sourceToken);
        assets[2] = IAsset(threeHop.sourceToken);
        assets[3] = IAsset(threeHop.targetToken);


        // init limits
        int256[] memory limits = new int256[](FOUR);
        limits[0] = int256(swaps[0].amount);
        limits[1] = 0;
        limits[2] = 0;
        limits[3] = 0;


        // init 
        IBalancerV2Vault.FundManagement memory funds = IBalancerV2Vault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: to,
            toInternalBalance: false
        }) ;
        

        SafeERC20.safeApprove(IERC20(firstHop.sourceToken), VAULT_ADDRESS, swaps[0].amount);
        IBalancerV2Vault(VAULT_ADDRESS).batchSwap(
            IBalancerV2Vault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            funds,
            limits,
            block.timestamp
        );
    }

    // GAS: 242782
    function _balanverV2ComposableSwapDoubleHop(
        address to,
        bytes memory moreInfo
    ) internal {
        (Hop memory firstHop, Hop memory secondHop) = abi.decode(moreInfo, (Hop,Hop) );


        address fromToken = firstHop.sourceToken;
        uint256 fromTokenAmount = IERC20(fromToken).balanceOf(address(this));

        // init swaps
        IBalancerV2Vault.BatchSwapStep[] memory swaps = new IBalancerV2Vault.BatchSwapStep[](TWO);
        swaps[0] = IBalancerV2Vault.BatchSwapStep({
            poolId: firstHop.poolId,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: fromTokenAmount,
            userData: bytes("")
        });

        swaps[1] = IBalancerV2Vault.BatchSwapStep({
            poolId: secondHop.poolId,
            assetInIndex: 1,
            assetOutIndex: 2,
            amount: 0, // depend on the actual amount
            userData: bytes("")
        });

        // init assets
        IAsset[] memory assets = new IAsset[](THREE);
        assets[0] = IAsset(firstHop.sourceToken);
        assets[1] = IAsset(secondHop.sourceToken);
        assets[2] = IAsset(secondHop.targetToken);

        // init limits
        int256[] memory limits = new int256[](THREE);
        limits[0] = int256(fromTokenAmount);
        limits[1] = 0;
        limits[2] = 0;


        // init 
        IBalancerV2Vault.FundManagement memory funds = IBalancerV2Vault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: to,
            toInternalBalance: false
        }) ;


        SafeERC20.safeApprove(IERC20(fromToken), VAULT_ADDRESS, fromTokenAmount);
        IBalancerV2Vault(VAULT_ADDRESS).batchSwap(
            IBalancerV2Vault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            funds,
            limits,
            block.timestamp
        );
    }


    function sellBase(
        address to,
        address,
        bytes memory moreInfo
    ) external override {
        (uint8 Hops, bytes memory data) = abi.decode( moreInfo, (uint8, bytes) );
        if (Hops == 2) {
            _balanverV2ComposableSwapDoubleHop(to, data);
        } else if (Hops == 3) {
            _balanverV2ComposableSwapTripleHop(to, data);
        } else {
            revert("Hops only can be 2 or 3.");
        }
    }

    function sellQuote(
        address to,
        address,
        bytes memory moreInfo
    ) external override {
        (uint8 Hops, bytes memory data) = abi.decode( moreInfo, (uint8, bytes) );
        if (Hops == 2) {
            _balanverV2ComposableSwapDoubleHop(to, data);
        } else if (Hops == 3) {
            _balanverV2ComposableSwapTripleHop(to, data);
        }  else {
            revert("Hops only can be 2 or 3.");
        }
    }



}