/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketMaker {
    struct PMMSwapRequest {
        uint256 pathIndex;
        address payer;
        address fromToken;
        address toToken;
        uint256 fromTokenAmountMax;
        uint256 toTokenAmountMax;
        uint256 salt;
        uint256 deadLine;
        bool isPushOrder;
        bytes extension;
        // address pmmAdapter;
        // uint256 subIndex;
        // bytes signature;
    }

    enum PMM_ERROR {
        NO_ERROR,
        INVALID_OPERATOR,
        INVALID_BACKEND,
        QUOTE_EXPIRED,
        REQUEST_TOO_MUCH,
        ORDER_CANCELLED_OR_FINALIZED,
        REMAINING_AMOUNT_NOT_ENOUGH,
        FROM_TOKEN_PAYER_ERROR,
        TO_TOKEN_PAYER_ERROR,
        WRONG_FROM_TOKEN
    }

    function dexRouterSwap(
        uint256 actualAmountRequest,
        address fromTokenpayer,
        PMMSwapRequest memory pmmRequest
    ) external returns (uint256);

    function approveProxy() external returns (address);
}
