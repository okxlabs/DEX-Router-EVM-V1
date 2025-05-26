// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.0;

import {IAdapter} from "../../interfaces/IAdapter.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {SafeERC20} from "../../libraries/SafeERC20.sol";
import {IWETH} from "../../interfaces/IWETH.sol";
import {IUniV3} from "../../interfaces/IUniV3.sol";
/// @dev specific flag for refund logic, "0x3ca20afc" is flexible and also used for commission, "ccc" mean refund
uint256 constant ORIGIN_PAYER = 0x3ca20afc2ccc0000000000000000000000000000000000000000000000000000;
uint256 constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

abstract contract BaseUniversalUniswapV3Adaptor is IAdapter {
    address public immutable WETH;
    uint160 public immutable MIN_SQRT_RATIO;
    uint160 public immutable MAX_SQRT_RATIO;

    /// @notice throw error when amount is not positive
    error InvalidAmount();
    /// @notice throw error when payer is not the contract itself or value is not required
    error InvalidPay();

    constructor(address weth, uint160 minSqrtRatio, uint160 maxSqrtRatio) {
        WETH = weth;
        MIN_SQRT_RATIO = minSqrtRatio;
        MAX_SQRT_RATIO = maxSqrtRatio;
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _sell(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _sell(to, pool, moreInfo);
    }

    function _sell(address to, address pool, bytes memory moreInfo) internal {
        (uint160 sqrtX96, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _uniswapV3Swap(to, pool, sqrtX96, data, _getPayerOrigin());
    }

    function _uniswapV3Swap(
        address to,
        address pool,
        uint160 sqrtX96,
        bytes memory data,
        uint256 payerOrigin
    ) internal {
        (address fromToken, address toToken) = abi.decode(
            data,
            (address, address)
        );
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroForOne = fromToken < toToken;
        // Call the pool's swap function
        IUniV3(pool).swap(
            to,
            zeroForOne,
            int256(sellAmount),
            sqrtX96 == 0
                ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
                : sqrtX96,
            data
        );
        /// @notice Refund logic: if there is leftover fromToken, refund to payerOrigin
        address _payerOrigin;
        if ((payerOrigin & ORIGIN_PAYER) == ORIGIN_PAYER) {
            _payerOrigin = address(uint160(uint256(payerOrigin) & ADDRESS_MASK));
        }
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        if (amount > 0 && _payerOrigin != address(0)) {
            SafeERC20.safeTransfer(IERC20(fromToken), _payerOrigin, amount);
        }
    }

    // Common internal callback logic for all V3-like protocols
    function _universalSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory data
    ) internal {
        if (amount0Delta <= 0 && amount1Delta <= 0) {
            revert InvalidAmount();
        }
        (address tokenIn, address tokenOut) = abi.decode(
            data,
            (address, address)
        );
        address tokenA = tokenIn;
        address tokenB = tokenOut;
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) {
            pay(tokenIn, address(this), msg.sender, amountToPay);
        } else {
            pay(tokenOut, address(this), msg.sender, amountToPay);
        }
    }

    /// @notice Internal function to handle token payments during swaps
    /// @dev This function handles two types of payments:
    ///      1. WETH payments: If the token is WETH and contract has enough ETH balance,
    ///         it will wrap ETH to WETH and transfer to recipient
    ///      2. ERC20 payments: If the payer is the contract itself, it will transfer
    ///         the ERC20 tokens directly to the recipient
    /// @param token The token address to pay with (WETH or ERC20)
    /// @param payer The address that should pay the tokens
    /// @param recipient The address that should receive the tokens
    /// @param value The amount of tokens to pay
    /// @custom:error InvalidPay Thrown when payer is not the contract itself
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        /// @notice pay with WETH
        if (token == WETH && address(this).balance >= value) {
            IWETH(WETH).deposit{value: value}();
            IWETH(WETH).transfer(recipient, value);
            /// @notice pay with ERC20
        } else if (payer == address(this)) {
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            revert InvalidPay();
        }
    }

    function _getPayerOrigin() internal pure returns (uint256 payerOrigin) {
        assembly {
            // Get the total size of the calldata
            let size := calldatasize()
            // Load the last 32 bytes of the calldata, which is assumed to contain the payer origin
            // Assumption: The calldata is structured such that the payer origin is always at the end
            payerOrigin := calldataload(sub(size, 32))
        }
    }

    // Fallback function to handle unexpected V3-like callbacks.
    // It expects calldata matching the (int256 amount0Delta, int256 amount1Delta, bytes memory data) signature
    // after the 4-byte function selector.
    fallback(bytes calldata _calldata) external returns (bytes memory) {
        (int256 amount0Delta, int256 amount1Delta, bytes memory data) = abi.decode(_calldata[4:], (int256, int256, bytes));
        _universalSwapCallback(amount0Delta, amount1Delta, data);

        // Uniswap V3 callbacks typically do not return values.
        // Returning empty bytes is standard for fallbacks that successfully handle a call
        // but don't have a specific return value defined by an interface.
        return bytes("");
    }
}
