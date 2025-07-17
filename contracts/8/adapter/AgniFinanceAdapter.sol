// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAgniFinance.sol";
import "../interfaces/IAgniFinanceCallback.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

contract AgniFinanceAdapter is IAdapter {
    address public immutable WMNT;

    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    constructor(address payable _WMNT) {
        WMNT = _WMNT;
    }

    function _agniFinanceSwap(address to, address pool, uint160 sqrtX96, bytes memory data) internal {
        (address fromToken, address toToken) = abi.decode(data, (address, address));
        
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroForOne = fromToken < toToken;

        IAgniFinance(pool).swap(
            to,
            zeroForOne,
            int256(sellAmount),
            sqrtX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1) : sqrtX96,
            data 
        );
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        (uint160 sqrtX96, bytes memory data) = abi.decode(moreInfo, (uint160, bytes));
        _agniFinanceSwap(to, pool, sqrtX96, data);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        (uint160 sqrtX96, bytes memory data) = abi.decode(moreInfo, (uint160, bytes));
        _agniFinanceSwap(to, pool, sqrtX96, data);
    }

    function agniSwapCallback(
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
        if (token == WMNT && address(this).balance >= value) {
            IWETH(WMNT).deposit{value: value}();
            IWETH(WMNT).transfer(recipient, value);
        } else if (payer == address(this)) {
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            revert("can not reach here");
        }
    }

}