// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISavingsDai.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract OriginWrapperAdapter is IAdapter {

    // fromToken == OToken
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (address tokenIn) = abi.decode(moreInfo, (address));
        uint256 assets = IERC20(tokenIn).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(tokenIn),
            pool,
            assets
        );
        ISavingsDai(pool).deposit(assets, to);
    }

    // fromToken == wrapped OToken
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (address tokenIn) = abi.decode(moreInfo, (address));
        uint256 shares = IERC20(tokenIn).balanceOf(address(this));
        ISavingsDai(pool).redeem(shares, to, address(this));
    }
}
