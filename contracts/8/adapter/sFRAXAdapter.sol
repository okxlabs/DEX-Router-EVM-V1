// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC4626.sol";
import "../libraries/SafeERC20.sol";

contract sFRAXAdapter is IAdapter {

    address public immutable SFRAX_ADDRESS;
    address public immutable FRAX_ADDRESS;

    constructor(address _sfrax) {
        SFRAX_ADDRESS = _sfrax;
        FRAX_ADDRESS = IERC4626(_sfrax).asset();
    }

    // frax -> sfrax
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        uint256 assets = IERC20(FRAX_ADDRESS).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(FRAX_ADDRESS),
            SFRAX_ADDRESS,
            assets
        );
        IERC4626(SFRAX_ADDRESS).deposit(assets, to);
    }

    // sfrax -> frax
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        uint256 shares = IERC20(SFRAX_ADDRESS).balanceOf(address(this));
        IERC4626(SFRAX_ADDRESS).redeem(shares, to, address(this));
    }
}