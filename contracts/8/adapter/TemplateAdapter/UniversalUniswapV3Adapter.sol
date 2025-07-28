// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.0;
import {BaseUniversalUniswapV3Adapter} from "./BaseUniversalUniswapV3Adapter.sol";

/**
 * @title UniversalUniswapV3Adapter
 * @notice Base contract for Universal Uniswap V3 Adapter implementation
 * @dev This contract serves as the foundation for adapting various Uniswap V3-like DEX protocols
 *
 * Supported DEX Protocols:
 * 1. Uniswap V3 Family:
 *    - Uniswap V3
 *    - Sheepdex
 *
 * 2. Algebra Family:
 *    - CamelotV3
 *    - KimV4
 *    - ThenaV2
 *    - Quickswapv3
 *    - HerculesV3
 *    - ZyberV3
 *
 * 3. Other V3-like DEXs:
 *    - Agni
 *    - FusionX
 *    - RamsesV2 (including NileCL)
 *    - Xei
 *    - PancakeV3
 *    - FireflyV3
 *
 * @custom:security-contact security@yourprotocol.com
 */
contract UniversalUniswapV3Adapter is BaseUniversalUniswapV3Adapter {
    constructor(
        address weth,
        uint160 minSqrtRatio,
        uint160 maxSqrtRatio
    ) BaseUniversalUniswapV3Adapter(weth, minSqrtRatio, maxSqrtRatio) {}

    // Uniswap V3 callback(
    // Sheepdex,
    // etc.)
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        _universalSwapCallback(amount0Delta, amount1Delta, data);
    }

    // Agni callback
    function agniSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        _universalSwapCallback(amount0Delta, amount1Delta, data);
    }

    // Algebra/Algebra-like callback (
    // CamelotV3,
    // KimV4,
    // ThenaV2,
    // Quickswapv3,
    // HerculesV3,
    // ZyberV3,
    // etc.)
    function algebraSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        _universalSwapCallback(amount0Delta, amount1Delta, data);
    }

    // FusionX callback
    function fusionXV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        _universalSwapCallback(amount0Delta, amount1Delta, data);
    }

    // RamsesV2 callback(
    // NileCL,
    // etc.)
    function ramsesV2SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        _universalSwapCallback(amount0Delta, amount1Delta, data);
    }

    // Xei callback
    function xeiV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        _universalSwapCallback(amount0Delta, amount1Delta, data);
    }

    // PancakeV3 callback
    function pancakeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        _universalSwapCallback(amount0Delta, amount1Delta, data);
    }

    // FireflyV3 callback
    function fireflyV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        _universalSwapCallback(amount0Delta, amount1Delta, data);
    }
}
