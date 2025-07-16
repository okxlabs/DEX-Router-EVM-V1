// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/INileCL.sol";

contract NileCLAdapter is IAdapter {
    using SafeERC20 for IERC20;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    address private _pool;

    /// @notice Called to `msg.sender` after executing a swap via IClPool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a ClPool deployed by the canonical ClPoolFactory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IClPoolActions#swap call
    function ramsesV2SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        data; // not used
        require(msg.sender == _pool, "only pool can callback");

        if (amount0Delta > 0) {
            IERC20(INileCL(_pool).token0()).safeTransfer(
                _pool,
                uint256(amount0Delta)
            );
        }
        if (amount1Delta > 0) {
            IERC20(INileCL(_pool).token1()).safeTransfer(
                _pool,
                uint256(amount1Delta)
            );
        }
    }

    function _nileCLSwap(
        address recipient,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken) = abi.decode(
            moreInfo,
            (address, address)
        );

        bool zeroForOne = fromToken < toToken;
        INileCL(pool).swap(
            recipient,
            zeroForOne,
            int256(IERC20(fromToken).balanceOf(address(this))),
            zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            ""
        );
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _pool = pool;
        _nileCLSwap(to, pool, moreInfo);
        _pool = address(0);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _pool = pool;
        _nileCLSwap(to, pool, moreInfo);
        _pool = address(0);
    }
}
