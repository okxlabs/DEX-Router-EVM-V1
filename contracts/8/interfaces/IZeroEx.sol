// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

struct LimitOrder {
    IERC20TokenV06 makerToken;
    IERC20TokenV06 takerToken;
    uint128 makerAmount;
    uint128 takerAmount;
    uint128 takerTokenFeeAmount;
    address maker;
    address taker;
    address sender;
    address feeRecipient;
    bytes32 pool;
    uint64 expiry;
    uint256 salt;
}

enum SignatureType {
    ILLEGAL,
    INVALID,
    EIP712,
    ETHSIGN,
    PRESIGNED
}

enum OrderStatus {
    INVALID,
    FILLABLE,
    FILLED,
    CANCELLED,
    EXPIRED
}

struct Signature {
    SignatureType signatureType;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct OrderInfo {
    bytes32 orderHash;
    OrderStatus status;
    uint128 takerTokenFilledAmount;
}

interface IZeroEx {
 
    function fillLimitOrder(
        LimitOrder calldata order,
        Signature calldata signature,
        uint128 takerTokenFillAmount
    ) external payable returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    function fillOrKillLimitOrder(
        LimitOrder calldata order,
        Signature calldata signature,
        uint128 takerTokenFillAmount
    ) external payable returns (uint128 makerTokenFilledAmount);

    function getLimitOrderInfo(
        LimitOrder calldata order
    ) external view returns (OrderInfo memory orderInfo);
}

interface IERC20TokenV06 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint8);
}

