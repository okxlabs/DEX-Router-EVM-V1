// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

uint256 constant POOL_TOKEN_AMOUNT= 3;

interface ICurve {
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function add_liquidity(
        uint256[POOL_TOKEN_AMOUNT] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function underlying_coins(int128 arg0) external view returns (address out);

    function coins(uint256 arg0) external view returns (address out);
}

interface ICurveForETH {
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) payable external;

    function underlying_coins(int128 arg0) external view returns (address out);

    function coins(int128 arg0) external view returns (address out);
}
