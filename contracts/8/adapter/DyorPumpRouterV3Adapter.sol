// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.17;

import {IAdapter} from "@dex/interfaces/IAdapter.sol";
import {IERC20} from "@dex/interfaces/IERC20.sol";
import {SafeERC20} from "@dex/libraries/SafeERC20.sol";
import {IUniswapV2Pair} from "@dex/interfaces/IUniswapV2Pair.sol";
import {IDyorPumpRouterV3, IDyorPoolV3} from "@dex/interfaces/IDyor.sol";
import {IWETH} from "@dex/interfaces/IWETH.sol";

/**
 * @title DyorPumpRouterV3Adapter
 * @notice DyorPumpRouterV3 adapter for DyorPumpRouterV3 DEX protocols
 * @dev Abstracts sellBase and sellQuote into a single optimized function
 * 
 * Supported DEX Protocols:
 *   1. DyorPumpRouterV3
 */
contract DyorPumpRouterV3Adapter is IAdapter {
    using SafeERC20 for IERC20;

    address private immutable dyorPumpRouterV3;
    address private immutable WETH;

    constructor(address _dyorPumpRouterV3, address _WETH) {
        dyorPumpRouterV3 = _dyorPumpRouterV3;
        WETH = _WETH;
    }

    /// @inheritdoc IAdapter
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _universalSwap(to, pool, moreInfo); 
    }

    /// @inheritdoc IAdapter
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _universalSwap(to, pool, moreInfo);
    }

    /**
     * @notice Universal swap function that handles both base and quote token swaps
     * @param moreInfo Additional configuration containing swap parameters
     */
    function _universalSwap(
        address , // to
        address , // pool - unused in this implementation
        bytes memory moreInfo
    ) internal {
        (uint256 amountIn, uint256 minAmountOut, address[] memory path) = _decodeMoreInfo(moreInfo);
        
        uint256 amountOut = _calculateAmountOutSimple(amountIn, path);
        if (path[0] == WETH) { // buy dyor token
            IWETH(WETH).withdraw(amountIn);
            IDyorPumpRouterV3(dyorPumpRouterV3).swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(
                amountOut,
                path,
                tx.origin, // must be tx.origin, and token will be received by tx.origin
                block.timestamp + 1000
            );
        } else { // sell dyor token
            /// @notice cause token will be transfer from tx.origin, so adapter can't use approve
            IDyorPumpRouterV3(dyorPumpRouterV3).swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountIn,
                amountOut,
                path,
                tx.origin, // must be tx.origin, and eth will be received by tx.origin
                address(0x7F1bb99Ad7770D999A3455275508b9EF9d052343),
                0,
                block.timestamp + 1000
            );
        }
    }

    function _calculateAmountOutSimple(
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256 amountOut) {
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 fee = 100;
        if (path[0] == WETH) {
            (reserveOut, reserveIn) = IDyorPoolV3(path[1]).getReserves();
            fee = 99;
        } else {
            (reserveIn, reserveOut) = IDyorPoolV3(path[0]).getReserves();
        }
        amountOut = _calculateAmountOut(amountIn, reserveIn, reserveOut, fee, 100);
        
        if (path[0] != WETH) {
            amountOut = amountOut * 99 / 100;
        }
    }

    /**
     * @notice Calculate output amount using optimized assembly
     * @param amountIn Input amount
     * @param reserveIn Input token reserve
     * @param reserveOut Output token reserve
     * @param feeNumerator Fee numerator
     * @param feeDenominator Fee denominator
     * @return amountOut Calculated output amount
     */
    function _calculateAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeNumerator,
        uint256 feeDenominator
    ) internal pure returns (uint256 amountOut) {
        assembly {
            // amountInWithFee = amountIn * feeNumerator
            let amountInWithFee := mul(amountIn, feeNumerator)
            
            // numerator = amountInWithFee * reserveOut
            let numerator := mul(amountInWithFee, reserveOut)
            
            // denominator = reserveIn * feeDenominator + amountInWithFee
            let denominator := add(mul(reserveIn, feeDenominator), amountInWithFee)
            
            // amountOut = numerator / denominator
            amountOut := div(numerator, denominator)
        }
    }

     /**
      * @notice Decode moreInfo parameter into swap configuration
      * @param moreInfo Encoded swap configuration
      * @return amountIn Amount in
      * @return minAmountOut Minimum amount out
      * @return path Path of tokens
      */
     function _decodeMoreInfo(bytes memory moreInfo) internal pure returns (uint256 amountIn, uint256 minAmountOut, address[] memory path) {
         (amountIn, minAmountOut, path) = abi.decode(moreInfo, (uint256, uint256, address[]));
     }

    receive() external payable {}
}