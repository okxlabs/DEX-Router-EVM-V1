// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAlgebraSwapCallback.sol";
import "../interfaces/IThenaV2.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/TickMath.sol";

contract ThenaV2Adapter is IAdapter, IAlgebraSwapCallback {
    // fetch from factory
    bytes32 immutable POOL_INIT_CODE_HASH;
    address immutable POOL_DEPLOYER;

    constructor(address _poolDeployer, bytes32 _poolInitCodeHash) {
        POOL_DEPLOYER = _poolDeployer;
        POOL_INIT_CODE_HASH = _poolInitCodeHash;
    }

    function _thenaV2Swap(
        address to,
        address pool,
        uint160 limitSqrtPrice,
        bytes memory data
    ) internal {
        (address tokenIn, address tokenOut) = abi.decode(
            data,
            (address, address)
        );

        uint256 sellAmount = IERC20(tokenIn).balanceOf(address(this));
        bool zeroToOne = tokenIn < tokenOut;

        IThenaV2(pool).swap(
            to,
            zeroToOne,
            int256(sellAmount),
            limitSqrtPrice == 0
                ? (
                zeroToOne
                    ? TickMath.MIN_SQRT_RATIO + 1
                    : TickMath.MAX_SQRT_RATIO - 1
            )
                : limitSqrtPrice,
            data
        );
    }

    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
       (uint160 limitSqrtPrice, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _thenaV2Swap(to, pool, limitSqrtPrice, data);
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint160 limitSqrtPrice, bytes memory data) = abi.decode(
            moreInfo,
            (uint160, bytes)
        );
        _thenaV2Swap(to, pool, limitSqrtPrice, data);
    }

    // for uniV3 callback
    function algebraSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0, "amount error"); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut) = abi.decode(
            _data,
            (address, address)
        );
        require(msg.sender == _computeAddress(tokenIn, tokenOut), "wrong msgSender");
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

    function _computeAddress(address token0, address token1) private view returns (address pool) {
        if (token0 > token1) {
            (token1, token0) = (token0, token1);
        }
        pool = address(uint160(uint256(keccak256(abi.encodePacked(hex'ff', POOL_DEPLOYER, keccak256(abi.encode(token0, token1)), POOL_INIT_CODE_HASH)))));
    }
}