// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/SafeERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/IAaveStaticAToken.sol";

contract AaveV3StaticATokenAdapter is IAdapter {
    using SafeERC20 for IERC20;

    function _aaveV3StaticATokenSwap(
        address to, // Recipient of the output token
        address pool, // Static aToken address
        bytes memory moreInfo
    ) internal {
        (address tokenIn, address tokenOut) = abi.decode(
            moreInfo,
            (address, address)
        );

        address aToken = address(IAaveStaticAToken(pool).aToken());
        address underlyingToken = IAaveStaticAToken(pool).asset();
        uint256 amount = IERC20(tokenIn).balanceOf(address(this));

        if (tokenIn == pool) {
            // convert share to token

            bool withdrawFromAave;
            if (tokenOut == aToken) {
                withdrawFromAave = false;
            } else if (tokenOut == underlyingToken) {
                withdrawFromAave = true;
            } else {
                revert("Invalid tokenOut");
            }

            IAaveStaticAToken(pool).redeem(
                amount,
                to,
                address(this),
                withdrawFromAave
            );
        } else {
            // convert token to share

            bool depositToAave;
            if (tokenIn == aToken) {
                depositToAave = false;
            } else if (tokenIn == underlyingToken) {
                depositToAave = true;
            } else {
                revert("Invalid tokenIn");
            }

            IERC20(tokenIn).safeApprove(pool, amount); // deposit() will call safeTransferFrom()
            IAaveStaticAToken(pool).deposit(amount, to, 0, depositToAave);
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _aaveV3StaticATokenSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _aaveV3StaticATokenSwap(to, pool, moreInfo);
    }
}
