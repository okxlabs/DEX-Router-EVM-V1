// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurveTNG {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 minDy, bool use_eth, address receiver)
        // use_eth: default false
        // receiver: default address(this)
        external;
    function coins(uint256 i) external view returns (address);
}
