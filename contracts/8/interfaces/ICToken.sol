// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICToken {
    function mint() external payable;
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function isCToken() external view returns (bool);
}
