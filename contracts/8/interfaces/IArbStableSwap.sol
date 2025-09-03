// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArbStableSwap {
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256 dy);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy
    ) external payable;

    function coins(uint256 i) external view returns (address);

    function N_COINS() external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function A() external view returns (uint256);

    function fee() external view returns (uint256);
}
