// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurveTNG {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 minDy, bool use_eth, address receiver)
        external;
    function coins(uint256 i) external view returns (address);
}
