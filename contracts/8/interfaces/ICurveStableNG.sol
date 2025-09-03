// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurveStableNG {
    function exchange_received(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy,
        address receiver
    )
        external;

    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external;

    function coins(uint256 i) external view returns (address);
}
