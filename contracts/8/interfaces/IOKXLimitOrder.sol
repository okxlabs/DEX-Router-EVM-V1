/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

struct Order {
    uint256 salt;
    address makerToken;
    address takerToken;
    address maker;
    address receiver;
    address allowedSender;
    uint256 makingAmount;
    uint256 takingAmount;
    uint256 minReturn;
    uint256 deadLine;
    bool partiallyAble;
}

struct Trade {
    bytes signature;
    address target;
    uint256 makingAmount;
    uint256 takingAmount;
    uint256 minReturn;
}

interface IOKXLimitOrder {
    function fillOrder(
        Order calldata _order,
        Trade calldata _trade
    ) external payable;

    function hashOrder(
        Order calldata order
    ) external view returns (bytes32 orderHash);
}
