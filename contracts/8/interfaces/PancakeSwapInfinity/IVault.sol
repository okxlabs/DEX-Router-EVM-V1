//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Currency} from "../../types/Currency.sol";
import {BalanceDelta} from "../../types/BalanceDelta.sol";
import {IVaultToken} from "./IVaultToken.sol";

interface IVault is IVaultToken {
    event AppRegistered(address indexed app);

    /// @notice Thrown when a app is not registered
    error AppUnregistered();

    /// @notice Thrown when a currency is not netted out after a lock
    error CurrencyNotSettled();

    /// @notice Thrown when there is already a locker
    /// @param locker The address of the current locker
    error LockerAlreadySet(address locker);

    /// @notice Thrown when passing in msg.value for non-native currency
    error SettleNonNativeCurrencyWithValue();

    /// @notice Thrown when `clear` is called with an amount that is not exactly equal to the open currency delta.
    error MustClearExactPositiveDelta();

    /// @notice Thrown when there is no locker
    error NoLocker();

    /// @notice Thrown when collectFee is attempted on a token that is synced.
    error FeeCurrencySynced();

    function isAppRegistered(address app) external returns (bool);

    /// @notice Returns the reserves for a a given pool type and currency
    function reservesOfApp(address app, Currency currency) external view returns (uint256);

    /// @notice register an app so that it can perform accounting base on vault
    function registerApp(address app) external;

    /// @notice Returns the locker who is locking the vault
    function getLocker() external view returns (address locker);

    /// @notice Returns the reserve and its amount that is currently being stored in trnasient storage
    function getVaultReserve() external view returns (Currency, uint256);

    /// @notice Returns lock data
    function getUnsettledDeltasCount() external view returns (uint256 count);

    /// @notice Get the current delta for a locker in the given currency
    /// @param currency The currency for which to lookup the delta
    function currencyDelta(address settler, Currency currency) external view returns (int256);

    /// @notice All operations go through this function
    /// @param data Any data to pass to the callback, via `ILockCallback(msg.sender).lockCallback(data)`
    /// @return The data returned by the call to `ILockCallback(msg.sender).lockCallback(data)`
    function lock(bytes calldata data) external returns (bytes memory);

    /// @notice Called by registered app to account for a change in the pool balance,
    /// convenient for AMM pool manager, typically after modifyLiquidity, swap, donate,
    /// include the case where hookDelta is involved
    /// @param currency0 The PoolKey currency0 to update
    /// @param currency1 The PoolKey currency1 to update
    /// @param delta The change in the pool's balance
    /// @param settler The address whose delta will be updated
    /// @param hookDelta The change in the pool's balance from hook
    /// @param hook The address whose hookDelta will be updated
    function accountAppBalanceDelta(
        Currency currency0,
        Currency currency1,
        BalanceDelta delta,
        address settler,
        BalanceDelta hookDelta,
        address hook
    ) external;

    /// @notice Called by registered app to account for a change in the pool balance,
    /// convenient for AMM pool manager, typically after modifyLiquidity, swap, donate
    /// @param currency0 The PoolKey currency0 to update
    /// @param currency1 The PoolKey currency1 to update
    /// @param delta The change in the pool's balance
    /// @param settler The address whose delta will be updated
    function accountAppBalanceDelta(Currency currency0, Currency currency1, BalanceDelta delta, address settler)
        external;

    /// @notice This works as a general accounting mechanism for non-dex app
    /// @param currency The currency to update
    /// @param delta The change in the balance
    /// @param settler The address whose delta will be updated
    function accountAppBalanceDelta(Currency currency, int128 delta, address settler) external;

    /// @notice Called by the user to net out some value owed to the user
    /// @dev Will revert if the requested amount is not available, consider using `mint` instead
    /// @dev Can also be used as a mechanism for free flash loans
    function take(Currency currency, address to, uint256 amount) external;

    /// @notice Writes the current ERC20 balance of the specified currency to transient storage
    /// This is used to checkpoint balances for the manager and derive deltas for the caller.
    /// @dev This MUST be called before any ERC20 tokens are sent into the contract, but can be skipped
    /// for native tokens because the amount to settle is determined by the sent value.
    /// However, if an ERC20 token has been synced and not settled, and the caller instead wants to settle
    /// native funds, this function can be called with the native currency to then be able to settle the native currency
    function sync(Currency token0) external;

    /// @notice Called by the user to pay what is owed
    function settle() external payable returns (uint256 paid);

    /// @notice Called by the user to pay on behalf of another address
    /// @param recipient The address to credit for the payment
    /// @return paid The amount of currency settled
    function settleFor(address recipient) external payable returns (uint256 paid);

    /// @notice WARNING - Any currency that is cleared, will be non-retreivable, and locked in the contract permanently.
    /// A call to clear will zero out a positive balance WITHOUT a corresponding transfer.
    /// @dev This could be used to clear a balance that is considered dust.
    /// Additionally, the amount must be the exact positive balance. This is to enforce that the caller is aware of the amount being cleared.
    function clear(Currency currency, uint256 amount) external;

    /// @notice Called by app to collect any fee related
    /// @dev no restriction on caller, underflow happen if caller collect more than the reserve
    function collectFee(Currency currency, uint256 amount, address recipient) external;

    /// @notice Called by the user to store surplus tokens in the vault
    function mint(address to, Currency currency, uint256 amount) external;

    /// @notice Called by the user to use surplus tokens for payment settlement
    function burn(address from, Currency currency, uint256 amount) external;
} 