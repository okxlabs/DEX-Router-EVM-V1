// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ILighterSwap.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract LighterswapAdapter is IAdapter {
    address private immutable router;

    constructor(address _router) {
        router = _router;
    }

    // fromToken == token0 WETH
    function sellBase(
        address to,
        address pool,
        bytes memory data
    ) external override {
        (uint64 priceBase, address fromToken, address toToken) = abi.decode(
            data,
            (uint64, address, address)
        );
        address token0 = ILighterPool(pool).token0();
        require(fromToken == token0, "fromToken mismatch token0");

        uint amount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), router, amount);
        uint8 poolId = ILighterPool(pool).orderBookId();
        uint sizeTick = ILighterPool(pool).sizeTick();

        uint64 amount0Base = uint64(amount / sizeTick);
        ILighterRouter(router).createMarketOrder(
            poolId,
            amount0Base,
            priceBase,
            true
        );

        require(
            IERC20(fromToken).balanceOf(address(this)) == 0,
            "can not leave dust"
        );

        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(toToken),
                to,
                IERC20(toToken).balanceOf(address(this))
            );
        }
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory data
    ) external override {
        (uint64 priceBase, address fromToken, address toToken) = abi.decode(
            data,
            (uint64, address, address)
        );
        address token1 = ILighterPool(pool).token1();
        require(fromToken == token1, "fromToken mismatch token1");

        uint amount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), router, amount);
        uint8 poolId = ILighterPool(pool).orderBookId();

        uint priceMultiplier = ILighterPool(pool).priceMultiplier();

        uint64 amount0Base = uint64(amount / priceBase / priceMultiplier);

        ILighterRouter(router).createMarketOrder(
            poolId,
            amount0Base,
            priceBase,
            false
        );

        require(
            IERC20(fromToken).balanceOf(address(this)) == 0,
            "can not leave dust"
        );

        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(toToken),
                to,
                IERC20(toToken).balanceOf(address(this))
            );
        }
    }
}
