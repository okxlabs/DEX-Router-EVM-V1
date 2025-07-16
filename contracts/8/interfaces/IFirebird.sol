// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IPair {

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getSwapFee() external view returns (uint32);

    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);
}
interface IFireBirdFormula {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 tokenWeightIn,
        uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint256 amountOut);
}
