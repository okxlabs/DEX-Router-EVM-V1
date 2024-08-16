// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISavings.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract stEURAdapter is IAdapter {
    address constant EURA = 0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8;
    address constant stEUR = 0x004626A008B1aCdC4c74ab51644093b155e59A23;

    // fromToken == EURA
    function sellBase(
        address to,
        address,
        bytes memory
    ) external override {
        uint256 assets = IERC20(EURA).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(EURA),
            stEUR,
            assets
        );
        ISavings(stEUR).deposit(assets, to);
    }

    // fromToken == stEUR
    function sellQuote(
        address to,
        address,
        bytes memory
    ) external override {
        uint256 shares = IERC20(stEUR).balanceOf(address(this));
        ISavings(stEUR).redeem(shares, to, address(this));
    }
}