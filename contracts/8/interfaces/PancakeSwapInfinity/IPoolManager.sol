//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IHooks} from "./IHooks.sol";
import {PoolKey} from "../../types/PancakeSwapInfinity/PoolKey.sol";
import {PoolId} from "../../types/PancakeSwapInfinity/PoolId.sol";
import {Currency} from "../../types/Currency.sol";

interface IPoolManager {
    /// @notice Thrown when trying to interact with a non-initialized pool
    error PoolNotInitialized();

    /// @notice PoolKey must have currencies where address(currency0) < address(currency1)
    error CurrenciesInitializedOutOfOrder(address currency0, address currency1);

    /// @notice Thrown when a call to updateDynamicLPFee is made by an address that is not the hook,
    /// or on a pool is not a dynamic fee pool.
    error UnauthorizedDynamicLPFeeUpdate();

    /// @notice Emitted when lp fee is updated
    /// @dev The event is emitted even if the updated fee value is the same as previous one
    event DynamicLPFeeUpdated(PoolId indexed id, uint24 dynamicLPFee);

    /// @notice Updates lp fee for a dyanmic fee pool
    /// @dev Some of the use case could be:
    ///   1) when hook#beforeSwap() is called and hook call this function to update the lp fee
    ///   2) For BinPool only, when hook#beforeMint() is called and hook call this function to update the lp fee
    ///   3) other use case where the hook might want to on an ad-hoc basis increase/reduce lp fee
    function updateDynamicLPFee(PoolKey memory key, uint24 newDynamicLPFee) external;

    /// @notice Return PoolKey for a given PoolId
    function poolIdToPoolKey(PoolId id)
        external
        view
        returns (
            Currency currency0,
            Currency currency1,
            IHooks hooks,
            IPoolManager poolManager,
            uint24 fee,
            bytes32 parameters
        );
} 