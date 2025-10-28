// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

uint256 constant POOL_TOKEN_AMOUNT= 3;

interface ICurve {
    // solium-disable-next-line mixedcase
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    // solium-disable-next-line mixedcase
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    // solium-disable-next-line mixedcase
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    // solium-disable-next-line mixedcase
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

    // view coins address
    function underlying_coins(int128 arg0) external view returns (address out);

    function coins(uint256 arg0) external view returns (address out);
}

interface ICurveForETH {
    // solium-disable-next-line mixedcase
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    // solium-disable-next-line mixedcase
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    // solium-disable-next-line mixedcase
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    // solium-disable-next-line mixedcase
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) payable external;

    // view coins address
    function underlying_coins(int128 arg0) external view returns (address out);

    function coins(int128 arg0) external view returns (address out);
}