// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IEulerSwap {
    /// @dev Immutable pool parameters. Passed to the instance via proxy trailing data.
    struct Params {
        // Entities
        address vault0;
        address vault1;
        address eulerAccount;
        // Curve
        uint112 equilibriumReserve0;
        uint112 equilibriumReserve1;
        uint256 priceX;
        uint256 priceY;
        uint256 concentrationX;
        uint256 concentrationY;
        // Fees
        uint256 fee;
        uint256 protocolFee;
        address protocolFeeRecipient;
    }

    /// @dev Starting configuration of pool storage.
    struct InitialState {
        uint112 currReserve0;
        uint112 currReserve1;
    }

    /// @notice Performs initial activation setup, such as approving vaults to access the
    /// EulerSwap instance's tokens, enabling vaults as collateral, setting up Uniswap
    /// hooks, etc. This should only be invoked by the factory.
    function activate(InitialState calldata initialState) external;

    /// @notice Retrieves the pool's immutable parameters.
    function getParams() external view returns (Params memory);

    /// @notice Retrieves the underlying assets supported by this pool.
    function getAssets() external view returns (address asset0, address asset1);

    /// @notice Retrieves the current reserves from storage, along with the pool's lock status.
    /// @return reserve0 The amount of asset0 in the pool
    /// @return reserve1 The amount of asset1 in the pool
    /// @return status The status of the pool (0 = unactivated, 1 = unlocked, 2 = locked)
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 status);

    /// @notice Generates a quote for how much a given size swap will cost.
    /// @param tokenIn The input token that the swapper SENDS
    /// @param tokenOut The output token that the swapper GETS
    /// @param amount The quantity of input or output tokens, for exact input and exact output swaps respectively
    /// @param exactIn True if this is an exact input swap, false if exact output
    /// @return The quoted quantity of output or input tokens, for exact input and exact output swaps respectively
    function computeQuote(address tokenIn, address tokenOut, uint256 amount, bool exactIn)
        external
        view
        returns (uint256);

    /// @notice Upper-bounds on the amounts of each token that this pool can currently support swaps for.
    /// @return limitIn Max amount of `tokenIn` that can be sold.
    /// @return limitOut Max amount of `tokenOut` that can be bought.
    function getLimits(address tokenIn, address tokenOut) external view returns (uint256 limitIn, uint256 limitOut);

    /// @notice Optimistically sends the requested amounts of tokens to the `to`
    /// address, invokes `eulerSwapCall` callback on `to` (if `data` was provided),
    /// and then verifies that a sufficient amount of tokens were transferred to
    /// satisfy the swapping curve invariant.
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}
