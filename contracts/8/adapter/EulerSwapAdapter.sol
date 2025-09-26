// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IEulerSwap.sol";
import "../libraries/SafeERC20.sol";

/**
 * @title EulerSwapAdapter
 * @dev Adapter contract for integrating EulerSwap into DexRouter
 * @dev Referencing EulerSwapPeriphery implementation, directly calling EulerSwap contract
 */
contract EulerSwapAdapter is IAdapter {
    /**
     * @dev Sell base token (asset0)
     * @param to Recipient of the swapped tokens
     * @param pool Pool contract address for the swap
     * @param moreInfo Additional swap data encoded as bytes
     *   Format: abi.encode(tokenIn, tokenOut)
     */
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external {
        _executeSwap(to, pool, moreInfo, true);
    }

    /**
     * @dev Sell quote token (asset1)
     * @param to Recipient of the swapped tokens
     * @param pool Pool contract address for the swap
     * @param moreInfo Additional swap data encoded as bytes
     *   Format: abi.encode(tokenIn, tokenOut)
     */
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external {
        _executeSwap(to, pool, moreInfo, false);
    }

    /**
     * @dev Internal function: Execute swap
     * @param to Recipient of the swapped tokens
     * @param pool Pool contract address for the swap
     * @param moreInfo Additional swap data encoded as bytes
     * @param zeroForOne true for selling base token (asset0), false for selling quote token (asset1)
     */
    function _executeSwap(
        address to,
        address pool,
        bytes memory moreInfo,
        bool zeroForOne
    ) internal {
        (address tokenIn, address tokenOut) = abi.decode(
            moreInfo,
            (address, address)
        );

        (address asset0, address asset1) = IEulerSwap(pool).getAssets();        
        require((zeroForOne && tokenIn == asset0 && tokenOut == asset1) || (!zeroForOne && tokenIn == asset1 && tokenOut == asset0), "Invalid token pair");

        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 amountOut = IEulerSwap(pool).computeQuote(tokenIn, tokenOut, amountIn, true);

        SafeERC20.safeTransfer(IERC20(tokenIn), pool, amountIn);
        
        if (zeroForOne) {
            // asset0 -> asset1, so amount0Out = 0, amount1Out = amountOut
            IEulerSwap(pool).swap(0, amountOut, to, "");
        } else {
            // asset1 -> asset0, so amount0Out = amountOut, amount1Out = 0
            IEulerSwap(pool).swap(amountOut, 0, to, "");
        }
    }
}