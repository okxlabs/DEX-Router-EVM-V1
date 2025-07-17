// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IRamsesV2.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

contract RamsesV2Adapter is IAdapter {
    address public immutable WETH;

    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    constructor(address payable weth) {
        WETH = weth;
    }

    function _ramsesV2Swap(address to, address pool, uint160 sqrtX96, bytes memory data) internal {
        (address fromToken, address toToken) = abi.decode(data, (address, address));
        
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroForOne = fromToken < toToken;

        IRamsesV2(pool).swap(
            to,
            zeroForOne,
            int256(sellAmount),
            sqrtX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1) : sqrtX96,
            data 
        );
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        (uint160 sqrtX96, bytes memory data) = abi.decode(moreInfo, (uint160, bytes));
        _ramsesV2Swap(to, pool, sqrtX96, data);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        (uint160 sqrtX96, bytes memory data) = abi.decode(moreInfo, (uint160, bytes));
        _ramsesV2Swap(to, pool, sqrtX96, data);
    }

    /// @notice Called to `msg.sender` after executing a swap via IRamsesV2Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// No more need : The caller of this method must be checked to be a RamsesV2Pool deployed by the canonical RamsesV2Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IRamsesV2PoolActions#swap call
    function ramsesV2SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        require(amount0Delta > 0 || amount1Delta > 0, "wrong amount"); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut) = abi.decode(data, (address, address));
        address tokenA = tokenIn;
        address tokenB = tokenOut;
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }

        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0 ? (tokenIn < tokenOut, uint256(amount0Delta)) : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) {
            pay(tokenIn, address(this), msg.sender, amountToPay);
        } else {
            pay(tokenOut, address(this), msg.sender, amountToPay);
        }
    }

    function pay(address token, address payer, address recipient, uint256 value) internal {
        if (token == WETH && address(this).balance >= value) {
            IWETH(WETH).deposit{value: value}();
            IWETH(WETH).transfer(recipient, value);
        } else if (payer == address(this)) {
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            revert("can not reach here");
        }
    }

}