// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

// PancakeSwap Infinity specific imports
import {IVault} from "../interfaces/PancakeSwapInfinity/IVault.sol";
import {ICLPoolManager} from "../interfaces/PancakeSwapInfinity/ICLPoolManager.sol";
import {IBinPoolManager} from "../interfaces/PancakeSwapInfinity/IBinPoolManager.sol";
import {PoolKey} from "../types/PancakeSwapInfinity/PoolKey.sol";
import {PoolId} from "../types/PancakeSwapInfinity/PoolId.sol";
import {Currency} from "../types/Currency.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {IHooks} from "../interfaces/PancakeSwapInfinity/IHooks.sol";
import {IPoolManager} from "../interfaces/PancakeSwapInfinity/IPoolManager.sol";
import {SafeCallback} from "../libraries/PancakeSwapInfinity/SafeCallback.sol";
import {SafeCast} from "../libraries/SafeCast.sol";

/// @title PancakeSwap Infinity Adapter for single hop swap
/// @notice Interacts with Infinity Vault and both CL/Bin PoolManagers to facilitate swaps
/// @dev Currently supports pools without hooks (hookPermissions = 0x0000)
///      Future versions may support dynamic hook permissions
///      
///      Note: Unlike UniV4Adapter, this adapter doesn't import TransientStateLibrary
///      because PancakeSwap Infinity provides transient state access through:
///      - vault.currencyDelta(settler, currency) for balance queries
///      - SettlementGuard.getCurrencyDelta() for internal state management
///      If advanced transient state operations are needed in the future,
///      consider integrating SettlementGuard library functions directly
contract PancakeSwapInfinityAdapter is IAdapter, SafeCallback {
    using SafeERC20 for IERC20;
    using SafeCast for *;

    address public immutable WNATIVE;
    address public immutable clPoolManager;
    address public immutable binPoolManager;
    
    uint160 internal constant MIN_SQRT_PRICE = 4295128739;
    uint160 internal constant MAX_SQRT_PRICE = 1461446703485210103287273052203988822378723970342;
    uint256 internal constant ORIGIN_PAYER =
        0x3ca20afc2ccc0000000000000000000000000000000000000000000000000000;

    error NotEnoughLiquidity(PoolId poolId);
    error UnsupportedPoolManager(address poolManager);
    event Received(address, uint256);

    struct PathKey {
        Currency inputCurrency;
        Currency outputCurrency;
        address poolManager;
        uint24 fee;
        uint256 poolParams; // For CL: tickSpacing (int24), For Bin: binStep (uint16)
    }

    constructor(IVault _vault, address _wnative, address _clPoolManager, address _binPoolManager) SafeCallback(_vault) {
        WNATIVE = _wnative;
        clPoolManager = _clPoolManager;
        binPoolManager = _binPoolManager;
    }

    function _setupPathKey(bytes calldata moreInfo) internal pure returns (PathKey memory) {
        (address tokenIn, address tokenOut, address poolManager, uint24 fee, uint256 poolParams) = abi.decode(moreInfo, (address, address, address, uint24, uint256));
        PathKey memory pathkey = PathKey({
            inputCurrency: Currency.wrap(tokenIn),
            outputCurrency: Currency.wrap(tokenOut),
            poolManager: poolManager,
            fee: fee,
            poolParams: poolParams
        });
        return pathkey;
    }

    function sellBase(
        address to,
        address /* pool */,
        bytes calldata moreInfo
    ) external override {
        uint256 payerOrigin;
        assembly {
            let size := calldatasize()
            payerOrigin := calldataload(sub(size, 32))
        }
        _lock(_setupPathKey(moreInfo), to, payerOrigin);
    }

    function sellQuote(
        address to,
        address /* pool */,
        bytes calldata moreInfo
    ) external override {
        uint256 payerOrigin;
        assembly {
            let size := calldatasize()
            payerOrigin := calldataload(sub(size, 32))
        }
        _lock(_setupPathKey(moreInfo), to, payerOrigin);
    }

    function _lock(PathKey memory pathkey, address to, uint256 payerOrigin) internal {
        uint256 amountIn;
        if (Currency.unwrap(pathkey.inputCurrency) == address(0)) {
            amountIn = IERC20(WNATIVE).balanceOf(address(this));
            IWETH(WNATIVE).withdraw(amountIn);
        } else {
            amountIn = IERC20(Currency.unwrap(pathkey.inputCurrency)).balanceOf(address(this));
        }
        bytes memory lockData = abi.encode(
            pathkey, 
            amountIn, 
            to,
            payerOrigin
        );
        vault.lock(lockData);
    }

    function _lockAcquired(bytes calldata data) internal override returns (bytes memory) {
        require(msg.sender == address(vault), "Unauthorized lockAcquired");

        (PathKey memory pathKey, uint256 amountIn, address to, uint256 payerOrigin) = abi.decode(data, (PathKey, uint256, address, uint256));

        address _payerOrigin;
        if ((payerOrigin & ORIGIN_PAYER) == ORIGIN_PAYER) {
            _payerOrigin = address(uint160(uint256(payerOrigin)));
        }

        (PoolKey memory poolKey, bool zeroForOne) = getPoolAndSwapDirection(pathKey, pathKey.inputCurrency); 

        (uint128 actualAmountIn, uint128 amountOut) = _swap(poolKey, zeroForOne, -int256(amountIn));
        
        require(amountOut > 0, "Amount must be positive");

        _settle(pathKey.inputCurrency, actualAmountIn);

        if (Currency.unwrap(pathKey.outputCurrency) == address(0)) { 
            _take(pathKey.outputCurrency, address(this), amountOut); 
            IWETH(WNATIVE).deposit{value: amountOut}(); 
            SafeERC20.safeTransfer(IERC20(WNATIVE), to, amountOut); 
        } else { 
            _take(pathKey.outputCurrency, to, amountOut); 
        }

        address fromToken = Currency.unwrap(pathKey.inputCurrency);

        if (fromToken == address(0)) {
            // Handle native token dust
            uint256 nativeBalance = address(this).balance;
            if (nativeBalance > 0 && _payerOrigin != address(0)) {
                (bool success, ) = _payerOrigin.call{value: nativeBalance}("");
                require(success, "Native transfer failed");
            }
        } else {
            // Handle ERC20 token dust
            uint amount = IERC20(fromToken).balanceOf(address(this));
            if (amount > 0 && _payerOrigin != address(0)) {
                (bool s, bytes memory res) = address(fromToken).call(abi.encodeWithSignature("transfer(address,uint256)", _payerOrigin, amount));
                require(s && (res.length == 0 || abi.decode(res, (bool))), "Transfer failed");
            }
        }

        return "";
    }

    function getPoolAndSwapDirection(PathKey memory params, Currency currencyIn)
        internal
        view
        returns (PoolKey memory poolKey, bool zeroForOne)
    {
        Currency currencyOut = params.outputCurrency;
        (Currency currency0, Currency currency1) =
            Currency.unwrap(currencyIn) < Currency.unwrap(currencyOut) ? (currencyIn, currencyOut) : (currencyOut, currencyIn);

        zeroForOne = Currency.unwrap(currencyIn) == Currency.unwrap(currency0);
        
        // Create the parameters bytes32 based on pool manager type
        bytes32 parameters = _encodePoolParameters(params.poolManager, params.poolParams);
        
        poolKey = PoolKey({
            currency0: currency0, 
            currency1: currency1, 
            hooks: IHooks(address(0)), 
            poolManager: IPoolManager(params.poolManager),
            fee: params.fee, 
            parameters: parameters
        });
    }

    /// @notice Encode pool parameters based on pool manager type
    /// @dev Currently hardcoded hookPermissions to 0x0000 (no hooks)
    ///      According to PancakeSwap Infinity spec:
    ///      - bytes32 parameters = hookPermissions(16 bits) + AMM-specific(16/24 bits)
    ///      
    ///      - CL pools: hookPermissions(16 bits) + tickSpacing(24 bits)
    ///         - example: 0x00000000000000000000000000000000000000000000000000000000000a00c2,
    ///         - Hook permission: 0x00c2 → 0000 0000 1100 0010 (in bits), support hook1,hook6,hook7
    ///         - Tick spacing: 0x00000a → decimal 10
    ///      - Bin pools: hookPermissions(16 bits) + binStep(16 bits)
    /// @param poolManager The address of the pool manager (CL or Bin)
    /// @param poolParams For CL: tickSpacing (int24), For Bin: binStep (uint16)
    /// @return parameters Encoded bytes32 parameters for PoolKey
    function _encodePoolParameters(address poolManager, uint256 poolParams) private view returns (bytes32 parameters) {
        // Hook permissions hardcoded to 0x0000 (first 16 bits = no hooks)
        uint16 hookPermissions = 0x0000;
        
        if (poolManager == clPoolManager) {
            // CL pools: hookPermissions(16 bits) + tickSpacing(24 bits)
            // Since hookPermissions = 0x0000, we can directly shift tickSpacing
            int24 tickSpacing = int24(int256(poolParams));
            uint256 encoded = (uint256(uint24(tickSpacing)) << 16) | uint256(hookPermissions);
            parameters = bytes32(encoded);
            
        } else if (poolManager == binPoolManager) {
            // Bin pools: hookPermissions(16 bits) + binStep(16 bits)
            // Since hookPermissions = 0x0000, we can directly shift binStep  
            uint16 binStep = uint16(poolParams);
            uint256 encoded = (uint256(binStep) << 16) | uint256(hookPermissions);
            parameters = bytes32(encoded);
            
        } else {
            revert UnsupportedPoolManager(poolManager);
        }
    }

    /// @notice if amountSpecified < 0, the swap is exactInput, otherwise exactOutput
    function _swap(PoolKey memory poolKey, bool zeroForOne, int256 amountSpecified)
        private
        returns (uint128 actualAmountIn, uint128 amountOut)
    {
        address poolManagerAddr = address(poolKey.poolManager);
        
        if (poolManagerAddr == clPoolManager) {
            return _swapCL(poolKey, zeroForOne, amountSpecified);
        } else if (poolManagerAddr == binPoolManager) {
            return _swapBin(poolKey, zeroForOne, amountSpecified);
        } else {
            revert UnsupportedPoolManager(poolManagerAddr);
        }
    }

    /// @notice Swap on Concentrated Liquidity Pool
    function _swapCL(PoolKey memory poolKey, bool zeroForOne, int256 amountSpecified)
        private
        returns (uint128 actualAmountIn, uint128 amountOut)
    {
        // for protection of exactOut swaps, sqrtPriceLimit is not exposed as a feature in this contract
        unchecked {
            ICLPoolManager poolManager = ICLPoolManager(address(poolKey.poolManager));
            BalanceDelta delta = poolManager.swap(
                poolKey,
                ICLPoolManager.SwapParams({
                    zeroForOne: zeroForOne, 
                    amountSpecified: amountSpecified, 
                    sqrtPriceLimitX96: zeroForOne ? MIN_SQRT_PRICE + 1 : MAX_SQRT_PRICE - 1
                }),
                ""
            );

            if (zeroForOne) {
                actualAmountIn = (-delta.amount0()).toUint128();
                amountOut = delta.amount1().toUint128();
            } else {
                actualAmountIn = (-delta.amount1()).toUint128();
                amountOut = delta.amount0().toUint128();
            }
        }
    }

    /// @notice Swap on Bin Pool (Liquidity Book)
    function _swapBin(PoolKey memory poolKey, bool zeroForOne, int256 amountSpecified)
        private
        returns (uint128 actualAmountIn, uint128 amountOut)
    {
        unchecked {
            IBinPoolManager poolManager = IBinPoolManager(address(poolKey.poolManager));
            
            // Convert zeroForOne to swapForY
            // zeroForOne = true means swapping currency0 for currency1 (X for Y)
            bool swapForY = zeroForOne;
            
            // BinPoolManager expects int128 instead of int256
            int128 binAmountSpecified = int128(amountSpecified);
            
            BalanceDelta delta = poolManager.swap(
                poolKey,
                swapForY,
                binAmountSpecified,
                ""
            );

            if (zeroForOne) {
                actualAmountIn = (-delta.amount0()).toUint128();
                amountOut = delta.amount1().toUint128();
            } else {
                actualAmountIn = (-delta.amount1()).toUint128();
                amountOut = delta.amount0().toUint128();
            }
        }
    }

    /// @notice Pay and settle a currency to the Vault
    function _settle(Currency currency, uint256 amount) internal {
        if (amount == 0) return;
        vault.sync(currency);
        if (currency.isAddressZero()) {
            vault.settle{value: amount}();
        } else {
            SafeERC20.safeTransfer(
                IERC20(Currency.unwrap(currency)),
                address(vault),
                amount
            );
            vault.settle();
        }
    }

    /// @notice Take an amount of currency out of the Vault
    function _take(Currency currency, address recipient, uint256 amount) internal {
        if (amount == 0) return;
        vault.take(currency, recipient, amount);
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
} 