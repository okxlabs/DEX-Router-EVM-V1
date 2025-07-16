// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IBancorNetworkV3Info {
    function tradeOutputBySourceAmount(
        address sourceToken,
        address targetToken,
        uint256 sourceAmount)
    external view returns (uint256);
}