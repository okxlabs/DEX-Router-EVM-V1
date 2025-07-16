// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISavings.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract stUSDAdapter is IAdapter {
    address constant USDA = 0x0000206329b97DB379d5E1Bf586BbDB969C63274;
    address constant stUSD = 0x0022228a2cc5E7eF0274A7Baa600d44da5aB5776;

    // fromToken == USDA
    function sellBase(
        address to,
        address,
        bytes memory
    ) external override {
        uint256 assets = IERC20(USDA).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(USDA),
            stUSD,
            assets
        );
        ISavings(stUSD).deposit(assets, to);
    }

    // fromToken == stUSD
    function sellQuote(
        address to,
        address,
        bytes memory
    ) external override {
        uint256 shares = IERC20(stUSD).balanceOf(address(this));
        ISavings(stUSD).redeem(shares, to, address(this));
    }
}