// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/INativeV3SwapCallback.sol";
import "../interfaces/INativeV3CreditVault.sol";
import "../interfaces/INativeLPToken.sol";
import "../interfaces/IUniV3.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/TickMath.sol";

/// @title NativeV3Adapter
/// @notice Only support ERC20 tokens as fromToken and toToken (including WETH)
/// @dev The fromToken and toToken in moreInfo are underlying tokens, the adapter will deposit underlying token to mint LP tokens
/// in callback method, then get the LP tokens with swap method, and finally redeem the LP tokens to underlying tokens.
contract NativeV3Adapter is IAdapter, INativeV3SwapCallback {
    uint256 internal constant ORIGIN_PAYER =
        0x3ca20afc2ccc0000000000000000000000000000000000000000000000000000;
    address public immutable CREDIT_VAULT;

    constructor(address creditVault) {
        CREDIT_VAULT = creditVault;
    }

    function _nativeV3Swap(
        address to,
        address pool,
        uint160 sqrtX96,
        bytes memory data,
        uint256 payerOrigin
    ) internal {
        require(to != address(0), "ZA");

        address _payerOrigin;
        if ((payerOrigin & ORIGIN_PAYER) == ORIGIN_PAYER) {
            _payerOrigin = address(uint160(uint256(payerOrigin)));
        }

        // the fromToken and toToken in data are the underlying tokens
        (
            address fromUnderlyingToken,
            address toUnderlyingToken,
            uint24 fee
        ) = abi.decode(data, (address, address, uint24));

        // get the lpToken of the underlying tokens
        address fromToken = INativeV3CreditVault(CREDIT_VAULT).lpTokens(
            fromUnderlyingToken
        );
        address toToken = INativeV3CreditVault(CREDIT_VAULT).lpTokens(
            toUnderlyingToken
        );

        // get the amount of LP token for a given underlying token balance
        uint256 sellAmount = INativeLPToken(fromToken).getSharesByUnderlying(
            IERC20(fromUnderlyingToken).balanceOf(address(this))
        );
        bool zeroForOne = fromToken < toToken;

        data = abi.encode(fromToken, toToken, fee);

        // NativeV3Pool shares the same swap function as UniV3Pool
        IUniV3(pool).swap(
            address(this),
            zeroForOne,
            int256(sellAmount),
            zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1,
            data
        );

        // redeem toToken to address to
        INativeLPToken(toToken).redeemTo(
            INativeLPToken(toToken).sharesOf(address(this)),
            to
        );

        // redeem the remaining LP tokens to the payerOrigin
        uint remainingFromShares = INativeLPToken(fromToken).sharesOf(
            address(this)
        );
        if (remainingFromShares > 0 && _payerOrigin != address(0)) {
            INativeLPToken(fromToken).redeemTo(
                remainingFromShares,
                _payerOrigin
            );
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 sqrtX96, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        uint256 payerOrigin;
        assembly {
            let size := calldatasize()
            payerOrigin := calldataload(sub(size, 32))
        }
        _nativeV3Swap(to, pool, sqrtX96, data, payerOrigin);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 sqrtX96, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        uint256 payerOrigin;
        assembly {
            let size := calldatasize()
            payerOrigin := calldataload(sub(size, 32))
        }
        _nativeV3Swap(to, pool, sqrtX96, data, payerOrigin);
    }

    function nativeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        // tokenIn and tokenOut are the lpTokens
        (address tokenIn, address tokenOut, ) = abi.decode(
            _data,
            (address, address, uint24)
        );

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) {
            pay(tokenIn, address(this), msg.sender, amountToPay);
        } else {
            tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
            pay(tokenIn, address(this), msg.sender, amountToPay);
        }
    }

    /// @param token The LP token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount of LP token to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        address underlying = INativeLPToken(token).underlying();
        uint256 underlyingAmount = INativeLPToken(token).getUnderlyingByShares(
            value
        );
        // approve LP token contract to transfer underlying token for deposit
        SafeERC20.safeApprove(IERC20(underlying), token, underlyingAmount);
        if (payer == address(this)) {
            // deposit owned underlying to mint LP tokens to recipient
            INativeLPToken(token).depositFor(recipient, underlyingAmount);
        } else {
            // transfer underlying from payer to this and deposit to mint LP tokens to recipient
            SafeERC20.safeTransferFrom(
                IERC20(underlying),
                payer,
                address(this),
                underlyingAmount
            );
            INativeLPToken(token).depositFor(recipient, underlyingAmount);
        }
    }
}
