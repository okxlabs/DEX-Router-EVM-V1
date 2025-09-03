// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Currency} from "../types/Currency.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {IHooks} from "./IHooks.sol";
import {IERC6909Claims} from "./external/IERC6909Claims.sol";
import {IProtocolFees} from "./IProtocolFees.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {PoolId} from "../types/PoolId.sol";
import {IExtsload} from "./IExtsload.sol";
import {IExttload} from "./IExttload.sol";

interface IPoolManager is IProtocolFees, IERC6909Claims, IExtsload, IExttload {
    error CurrencyNotSettled();

    error PoolNotInitialized();

    error AlreadyUnlocked();

    error ManagerLocked();

    error TickSpacingTooLarge(int24 tickSpacing);

    error TickSpacingTooSmall(int24 tickSpacing);

    error CurrenciesOutOfOrderOrEqual(address currency0, address currency1);

    error UnauthorizedDynamicLPFeeUpdate();

    error SwapAmountCannotBeZero();

    error NonzeroNativeValue();

    error MustClearExactPositiveDelta();

    event Initialize(
        PoolId indexed id,
        Currency indexed currency0,
        Currency indexed currency1,
        uint24 fee,
        int24 tickSpacing,
        IHooks hooks,
        uint160 sqrtPriceX96,
        int24 tick
    );

    event ModifyLiquidity(
        PoolId indexed id, address indexed sender, int24 tickLower, int24 tickUpper, int256 liquidityDelta, bytes32 salt
    );

    event Swap(
        PoolId indexed id,
        address indexed sender,
        int128 amount0,
        int128 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick,
        uint24 fee
    );

    event Donate(PoolId indexed id, address indexed sender, uint256 amount0, uint256 amount1);

    function unlock(bytes calldata data) external returns (bytes memory);

    function initialize(PoolKey memory key, uint160 sqrtPriceX96) external returns (int24 tick);

    struct ModifyLiquidityParams {
        int24 tickLower;
        int24 tickUpper;
        int256 liquidityDelta;
        bytes32 salt;
    }

    function modifyLiquidity(PoolKey memory key, ModifyLiquidityParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta callerDelta, BalanceDelta feesAccrued);

    struct SwapParams {
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }

    function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta swapDelta);

    function donate(PoolKey memory key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        external
        returns (BalanceDelta);

    function sync(Currency currency) external;

    function take(Currency currency, address to, uint256 amount) external;

    function settle() external payable returns (uint256 paid);

    function settleFor(address recipient) external payable returns (uint256 paid);

    function clear(Currency currency, uint256 amount) external;

    function mint(address to, uint256 id, uint256 amount) external;

    function burn(address from, uint256 id, uint256 amount) external;

    function updateDynamicLPFee(PoolKey memory key, uint24 newDynamicLPFee) external;
}
