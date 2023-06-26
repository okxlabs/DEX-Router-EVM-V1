// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArbStableSwap {
    // solium-disable-next-line mixedcase
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256 dy);

    // solium-disable-next-line mixedcase
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy
    ) external payable;

    // solium-disable-next-line mixedcase
    function coins(uint256 i) external view returns (address);

    // solium-disable-next-line mixedcase
    function N_COINS() external view returns (uint256);

    // solium-disable-next-line mixedcase
    function balances(uint256 i) external view returns (uint256);

    // solium-disable-next-line mixedcase
    function A() external view returns (uint256);

    // solium-disable-next-line mixedcase
    function fee() external view returns (uint256);
}