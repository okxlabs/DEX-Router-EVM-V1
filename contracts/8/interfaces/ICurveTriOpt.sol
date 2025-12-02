// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurveTriOpt {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 minDy, address receiver) external payable returns(uint256[2] memory);
    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 minDy, address receiver) external payable returns(uint256[2] memory);
    function coins(uint256 i) external view returns (address);
}
