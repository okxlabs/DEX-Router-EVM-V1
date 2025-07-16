// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IPoolManager.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {Currency} from "../types/Currency.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {SafeCallback} from "../libraries/SafeCallback.sol";
import "../libraries/TransientStateLibrary.sol";

/// @title UniV4Adapter
/// @notice Interacts with PoolManager to facilitate Uniswap V4 swaps
contract UniV4AdapterV2 is IAdapter, SafeCallback {
    using SafeERC20 for IERC20;
    using TransientStateLibrary for IPoolManager;

    address public immutable WETH;
    uint160 internal constant MIN_SQRT_PRICE = 4295128739;
    uint160 internal constant MAX_SQRT_PRICE = 1461446703485210103287273052203988822378723970342;

    error NotEnoughLiquidity(PoolId poolId);
    event Received(address, uint256);

    struct PathKey {
        Currency inputCurrency;
        Currency intermediateCurrency;
        uint24 fee;
        int24 tickSpacing;
    }

    constructor(address _poolManager, address _weth) SafeCallback(IPoolManager(_poolManager)) {
        WETH = _weth;
    }

    function sellBase(
        address to,
        address /* pool */,
        bytes calldata moreInfo
    ) external override {
        (PathKey[] memory pathkey) = abi.decode(moreInfo, (PathKey[]));
        _unlock(pathkey, to);
    }

    function sellQuote(
        address to,
        address /* pool */,
        bytes calldata moreInfo
    ) external override {
        (PathKey[] memory pathkey) = abi.decode(moreInfo, (PathKey[]));
        _unlock(pathkey, to);
    }

    function _unlock(PathKey[] memory pathkey, address to) internal {
        uint256 amountIn;
        if (Currency.unwrap(pathkey[0].inputCurrency) == address(0)) {
            amountIn = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amountIn);
        } else {
            amountIn = IERC20(Currency.unwrap(pathkey[0].inputCurrency)).balanceOf(address(this));
        }
        bytes memory unlockdata = abi.encode(
            pathkey, 
            amountIn, 
            to
        );
        poolManager.unlock(unlockdata);
    }

    function _unlockCallback(bytes calldata data) internal override returns (bytes memory) {
        require(msg.sender == address(poolManager), "Unauthorized unlockCallback");

        (PathKey[] memory pathKey, uint256 amountExactIn, address to) = 
            abi.decode(data, (PathKey[], uint256, address));

        BalanceDelta swapDelta; 
        Currency inputCurrency = pathKey[0].inputCurrency;
        uint256 amountIn = amountExactIn;
        
        for (uint256 i = 0; i < pathKey.length; i++) { 
            (PoolKey memory poolKey, bool zeroForOne) = getPoolAndSwapDirection(pathKey[i], pathKey[i].inputCurrency); 

            swapDelta = _swap(
                poolKey, 
                zeroForOne, 
                -int256(amountIn)
            ); 

            amountIn = zeroForOne ? uint128(swapDelta.amount1()) : uint128(swapDelta.amount0()); 
            inputCurrency = pathKey[i].intermediateCurrency;
        }
        
        require(amountIn > 0, "Amount must be positive");
        uint256 amountOut = uint256(uint128(amountIn));

        _settle(pathKey[0].inputCurrency, amountExactIn); 

        if (Currency.unwrap(inputCurrency) == address(0)) { 
            _take(inputCurrency, address(this), amountOut); 
            IWETH(WETH).deposit{value: amountOut}(); 
            SafeERC20.safeTransfer(IERC20(WETH), to, amountOut); 
        } else { 
            _take(inputCurrency, to, amountOut); 
        } 
       
        return "";
    }

    function getPoolAndSwapDirection(PathKey memory params, Currency currencyIn)
        internal
        pure
        returns (PoolKey memory poolKey, bool zeroForOne)
    {
        Currency currencyOut = params.intermediateCurrency;
        (Currency currency0, Currency currency1) =
            Currency.unwrap(currencyIn) < Currency.unwrap(currencyOut) ? (currencyIn, currencyOut) : (currencyOut, currencyIn);

        zeroForOne = Currency.unwrap(currencyIn) == Currency.unwrap(currency0);
        poolKey = PoolKey(currency0, currency1, params.fee, params.tickSpacing, IHooks(address(0)));
    }

    function _swap(PoolKey memory poolKey, bool zeroForOne, int256 amountSpecified)
        internal
        returns (BalanceDelta swapDelta)
    {
        swapDelta = poolManager.swap(
            poolKey,
            IPoolManager.SwapParams({
                zeroForOne: zeroForOne,
                amountSpecified: amountSpecified,
                sqrtPriceLimitX96: zeroForOne ? MIN_SQRT_PRICE + 1 : MAX_SQRT_PRICE - 1
            }),
            ""
        );

        // Check that the pool was not illiquid.
        int128 amountSpecifiedActual = (zeroForOne == (amountSpecified < 0)) ? swapDelta.amount0() : swapDelta.amount1();
        if (amountSpecifiedActual != amountSpecified) revert NotEnoughLiquidity(poolKey.toId());
    }

    function _settle(Currency currency, uint256 amount) internal {
        if (amount == 0) return;
        poolManager.sync(currency);
        if (currency.isAddressZero()) {
            poolManager.settle{value: amount}();
        } else {
            _pay(currency, amount);
            poolManager.settle();
        }
    }

    function _pay(Currency token, uint256 amount) internal {
        if (amount == 0) return;
        SafeERC20.safeTransfer(
            IERC20(Currency.unwrap(token)),
            address(poolManager),
            amount
        );
    }

    function _take(Currency currency, address recipient, uint256 amount) internal {
        if (amount == 0) return;
        poolManager.take(currency, recipient, amount);
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}