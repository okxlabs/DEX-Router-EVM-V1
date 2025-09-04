// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

interface IBancorNetworkV3 {
    function tradeBySourceAmount(
        address sourceToken,
        address targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount,
        uint256 deadline,
        address beneficiary
    ) external payable returns (uint256);
}
