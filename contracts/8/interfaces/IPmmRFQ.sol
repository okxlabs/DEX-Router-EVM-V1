/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

struct OrderRFQ {
    uint256 info; // lowest 64 bits is the order id, next 64 bits is the expiration timestamp
    address makerAsset;
    address takerAsset;
    address maker;
    address allowedSender; // equals to Zero address on public orders
    uint256 makingAmount;
    uint256 takingAmount;
    address settler;
}

interface IPmmRFQ {
    function fillOrderRFQTo(
        OrderRFQ memory order,
        bytes calldata signature,
        uint256 flagsAndAmount,
        address target
    )
        external
        payable
        returns (
            uint256 filledMakingAmount,
            uint256 filledTakingAmount,
            bytes32 orderHash
        );
}
