// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.17;

import {IAdapter} from "@dex/interfaces/IAdapter.sol";
import {IERC20} from "@dex/interfaces/IERC20.sol";
import {SafeERC20} from "@dex/libraries/SafeERC20.sol";
import {IUniswapV2Pair} from "@dex/interfaces/IUniswapV2Pair.sol";
import {IDyorPumpRouterV3, IDyorPoolV3} from "@dex/interfaces/IDyor.sol";
import {RestrictedLiquidityLib, RefundLib} from "@dex/libraries/Adapters.sol";
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

    // direction: true for buy meme, false for sell meme
    event OrderRecord(bool direction, address fromToken, address toToken, uint256 fromAmount, uint256 toAmount);
    
    constructor(address _dyorPumpRouterV3, address _WETH) {
        dyorPumpRouterV3 = _dyorPumpRouterV3;
        WETH = _WETH;
    }

    /// @inheritdoc IAdapter
    function sellBase(
        address to, // to, not used, cause dyor will send token to tx.origin
        address pool,
        bytes memory moreInfo
    ) external override {
        _universalSwap(to, pool, true, moreInfo);
    }

    /// @inheritdoc IAdapter
    function sellQuote(
        address to, // to, not used, cause dyor will send token to tx.origin
        address pool,
        bytes memory moreInfo
    ) external override {
        _universalSwap(to, pool ,false, moreInfo);
    }

    /**
     * @notice Universal swap function that handles both base and quote token swaps
     * @param moreInfo Additional configuration containing swap parameters
     */
    function _universalSwap(
        address ,
        address pool,
        bool isSellBase,
        bytes memory moreInfo
    ) internal {
        address[] memory path = new address[](2);
        if (isSellBase) { // sell eth 
            path[0] = WETH;
            path[1] = pool;
            uint256 amountIn = IERC20(WETH).balanceOf(address(this));
            uint256 amountOut = _calculateAmountOutSimple(pool,amountIn, path);
            IWETH(WETH).withdraw(amountIn);
            IDyorPumpRouterV3(dyorPumpRouterV3).swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(
                amountOut,
                path,
                tx.origin, // must be tx.origin, and token will be received by tx.origin
                block.timestamp + 1000
            );
            /// @notice if dyorfun retrun eth, adapter will receive eth, so adapter will send eth to payerOrigin
            address payerOrigin = RefundLib.getPayerOrigin();
            uint256 remainAmount = address(this).balance;
            if (remainAmount > 0) {
                if (payerOrigin != address(0)) {
                    payable(payerOrigin).transfer(remainAmount);
                } else {
                    payable(tx.origin).transfer(remainAmount);
                }
            }
        } else { ///@notice sell dyor token is restricted liquidity, have to use tradeInfo to build moreinfo
            path[0] = pool;
            path[1] = WETH;
            uint256 amountOut = tx.origin.balance; // eth balance
            RestrictedLiquidityLib.TradeInfo memory tradeInfo = abi.decode(moreInfo, (RestrictedLiquidityLib.TradeInfo));
            require(tradeInfo.fundAddress == pool, "DyorPumpRouterV3Adapter: sell token is not meme");
            require(tradeInfo.tokenAddress == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || 
            tradeInfo.tokenAddress == WETH, "DyorPumpRouterV3Adapter: buy token is not OKB");
            uint256 amountIn = tradeInfo.sellMemeAmount;
            uint256 minReturn = _calculateAmountOutSimple(pool, amountIn, path);
            require(minReturn >= tradeInfo.minReturnAmount, "DyorPumpRouterV3Adapter: Min return not reached");
            /// @notice cause token will be transfer from tx.origin, so adapter can't use approve
            IDyorPumpRouterV3(dyorPumpRouterV3).swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountIn,
                minReturn,
                path,
                tx.origin, // must be tx.origin, and eth will be received by tx.origin
                tx.origin,
                0,
                block.timestamp + 1000
            );
            amountOut = tx.origin.balance - amountOut;
            require(amountOut >= minReturn, "DyorPumpRouterV3Adapter: Min return not reached");
            emit OrderRecord(false, tradeInfo.fundAddress, tradeInfo.tokenAddress, amountIn, amountOut);
        }
    }

    function _calculateAmountOutSimple(
        address pool,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256 amountOut) {
        uint256 reserveIn; // sell token amount path[0]
        uint256 reserveOut; // buy token amount path[1]
        uint256 fee = 100;
        IDyorPoolV3 dyorPoolV3 = IDyorPoolV3(pool);
        (reserveIn, reserveOut) = dyorPoolV3.getReserves(); // token0, token1

        if (dyorPoolV3.token0() != path[0]) { // sell token is token1
            (reserveIn, reserveOut) = (reserveOut, reserveIn);
        }

        if (path[0] == WETH) {
            fee = 99; // sell eth, so 1% fee
        } 
        amountOut = _calculateAmountOut(amountIn, reserveIn, reserveOut, fee, 100);
        // after swap if token is weth, dyor will take 1% fee, 
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

    receive() external payable {}
}