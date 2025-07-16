// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISolidlyV3.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/TickMath.sol";

/// @title SolidlyV3Adapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract SolidlyV3Adapter is IAdapter {
    // address public immutable FACTROY_ADDRESS;

    // constructor(address  _factory) {
    //     FACTROY_ADDRESS = _factory;
    // }

    function _solidlyV3Swap(
        address to,
        address pool,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) internal {
        (address fromToken, address toToken, ) = abi.decode(
            data,
            (address, address, uint24)
        );

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroToOne = fromToken < toToken;

        SafeERC20.safeApprove(
            IERC20(fromToken),
            pool,
            sellAmount
        );

        ISolidlyV3(pool).swap(
            to,
            zeroToOne,
            int256(sellAmount),
            sqrtPriceLimitX96 == 0
                ? (
                    zeroToOne
                        ? TickMath.MIN_SQRT_RATIO + 1
                        : TickMath.MAX_SQRT_RATIO - 1
                )
                : sqrtPriceLimitX96
        );
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 sqrtPriceLimitX96, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _solidlyV3Swap(to, pool, sqrtPriceLimitX96, data);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 sqrtPriceLimitX96, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _solidlyV3Swap(to, pool, sqrtPriceLimitX96, data);
    }

    
}
