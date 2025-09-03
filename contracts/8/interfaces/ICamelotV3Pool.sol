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
