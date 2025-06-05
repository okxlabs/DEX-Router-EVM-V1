// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISmardex.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract SmardexAdapterWithRefund is IAdapter, ISmardexSwapCallback {
    /// @dev specific flag for refund logic, "0x3ca20afc" is flexible and also used for commission, "ccc" mean refund
    uint256 constant ORIGIN_PAYER = 0x3ca20afc2ccc0000000000000000000000000000000000000000000000000000;
    uint256 constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    function _smardexSwap(
        address to,
        address pool,
        bytes memory data,
        uint256 payerOrigin
    ) internal {
        (address fromToken, address toToken) = abi.decode(
            data,
            (address, address)
        );

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroForOne = fromToken < toToken;

        ISmardexPair(pool).swap(
            to,
            zeroForOne,
            int256(sellAmount),
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
    
    
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _smardexSwap(to, pool, moreInfo, _getPayerOrigin());
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _smardexSwap(to, pool, moreInfo, _getPayerOrigin());
    }

    function smardexSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut) = abi.decode(
            _data,
            (address, address)
        );

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));

        if (isExactInput) {
            SafeERC20.safeTransfer(IERC20(tokenIn), msg.sender, amountToPay);
        } else {
            tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
            SafeERC20.safeTransfer(IERC20(tokenIn), msg.sender, amountToPay);
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
} 