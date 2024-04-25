// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISavingsDai.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract sDAIAdapter is IAdapter {
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant sDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;

    // fromToken == DAI
    function sellBase(
        address to,
        address pool,
        bytes memory
    ) external override {
        uint256 assets = IERC20(DAI).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(DAI),
            sDAI,
            assets
        );
        ISavingsDai(pool).deposit(assets, to);
    }

    // fromToken == sDAI
    function sellQuote(
        address to,
        address pool,
        bytes memory
    ) external override {
        uint256 shares = IERC20(sDAI).balanceOf(address(this));
        ISavingsDai(pool).redeem(shares, to, address(this));
    }
}
