// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ICurveV2.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

contract PancakestableAdapter is IAdapter {

    function _pancakestableSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken, uint256 i, uint256 j) = abi.decode(
            moreInfo,
            (address, address, uint256, uint256)
        );
    
        uint256 sellAmount = 0;

        sellAmount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);
        ICurveV2(pool).exchange(
            i,
            j,
            sellAmount,
            0
        );

        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(toToken),
                to,
                IERC20(toToken).balanceOf(address(this))
            );
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _pancakestableSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _pancakestableSwap(to, pool, moreInfo);
    }

}
