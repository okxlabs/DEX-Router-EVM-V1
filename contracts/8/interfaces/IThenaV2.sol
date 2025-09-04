// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IThenaV2 {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function swap(
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function globalState()
    external
    view
    returns (
        uint160 price,
        int24 tick,
        uint16 fee,
        uint16 timepointIndex,
        uint8 communityFeeToken0,
        uint8 communityFeeToken1,
        bool unlocked
    );

}
