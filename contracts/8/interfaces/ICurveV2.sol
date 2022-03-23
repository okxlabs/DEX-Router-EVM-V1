// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface ICurveV2 {
    // solium-disable-next-line mixedcase
    function get_dy(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    // solium-disable-next-line mixedcase
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy, bool use_eth) external;

    // view coins address
    function underlying_coins(int128 arg0) external view returns(address out);
    function coins(int128 arg0) external view returns(address out);

}