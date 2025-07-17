// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurveStableNG {
    /**
    Use this method instead of exchange as it will save gas by using the curve contract's internal 
    balances check, which means the dexRouter could send token directly to pool instead of sending 
    to the adapter first, which could save gas for a transferFrom action
     */
    function exchange_received(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy,
        address receiver
    )
        // receiver: default address(this)
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