//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolManager} from "./IPoolManager.sol";
import {PoolKey} from "../../types/PancakeSwapInfinity/PoolKey.sol";
import {PoolId} from "../../types/PancakeSwapInfinity/PoolId.sol";
import {BalanceDelta} from "../../types/BalanceDelta.sol";
import {Currency} from "../../types/Currency.sol";

interface IBinPoolManager is IPoolManager {
    /// @notice Error thrown when amount specified is 0 in swap
    error AmountSpecifiedIsZero();

    /// @notice Get the current value in slot0 of the given pool
    function getSlot0(PoolId id) external view returns (uint24 activeId, uint24 protocolFee, uint24 lpFee);

    /// @notice Initialize a new pool
    function initialize(PoolKey memory key, uint24 activeId) external;

    /// @notice Perform a swap to a pool
    /// @param key The pool key
    /// @param swapForY If true, swap token X for Y, if false, swap token Y for X
    /// @param amountSpecified If negative, imply exactInput, if positive, imply exactOutput.
    /// @param hookData Any data to pass to the callback
    /// @return delta The balance delta of the address swapping
    function swap(PoolKey memory key, bool swapForY, int128 amountSpecified, bytes calldata hookData)
        external
        returns (BalanceDelta delta);

    /// @notice Returns the reserves of a bin
    /// @param id The pool id
    /// @param binId The id of the bin
    /// @return binReserveX The reserve of token X in the bin
    /// @return binReserveY The reserve of token Y in the bin
    /// @return binLiquidity The total liquidity in the bin
    /// @return totalShares The total shares minted in the bin
    function getBin(PoolId id, uint24 binId)
        external
        view
        returns (uint128 binReserveX, uint128 binReserveY, uint256 binLiquidity, uint256 totalShares);

    /// @notice Returns the next non-empty bin
    /// @param id The pool id
    /// @param swapForY Whether the swap is for token Y (true) or token X (false)
    /// @param binId The id of the bin
    /// @return nextId The id of the next non-empty bin
    function getNextNonEmptyBin(PoolId id, bool swapForY, uint24 binId) external view returns (uint24 nextId);
}