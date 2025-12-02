// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICamelotV3Pool {
    function getReserves() external view returns (uint128, uint128);

    function swap(
        address recipient,
        bool zeroToOne,
        int256 amountRequired,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    /// @notice The globalState structure in the pool stores many values but requires only one slot
    /// and is exposed as a single method to save gas when accessed externally.
    /// @return price The current price of the pool as a sqrt(dToken1/dToken0) Q64.96 value;
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run;
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick boundary;
    /// @return feeZtO The last pool fee value for ZtO swaps in hundredths of a bip, i.e. 1e-6;
    /// @return feeOtZ The last pool fee value for OtZ swaps in hundredths of a bip, i.e. 1e-6;
    /// @return timepointIndex The index of the last written timepoint
    /// @return communityFee The community fee percentage of the swap fee in thousandths (1e-3)
    /// @return unlocked Whether the pool is currently locked to reentrancy
    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            uint16 feeZtO,
            uint16 feeOtZ,
            uint16 timepointIndex,
            uint8 communityFee,
            bool unlocked
        );
}
