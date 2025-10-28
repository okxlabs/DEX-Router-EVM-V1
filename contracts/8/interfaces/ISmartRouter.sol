// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IMarketMaker.sol";
import "../libraries/PMMLib.sol";

interface ISmartRouter {
    struct BaseRequest {
        uint256 fromToken;
        address toToken;
        uint256 fromTokenAmount;
        uint256 minReturnAmount;
        uint256 deadLine;
    }

    struct RouterPath {
        address[] mixAdapters;
        address[] assetTo;
        uint256[] rawData;
        bytes[] extraData;
        uint256 fromToken;
    }

    function smartSwap(
        BaseRequest calldata baseRequest,
        uint256[] calldata batchesAmount,
        RouterPath[][] calldata batches,
        PMMLib.PMMSwapRequest[] calldata extraData,
        address payer,
        address receiver
    ) external payable returns (uint256 returnAmount);

    function smartSwapByInvest(
        BaseRequest calldata baseRequest,
        uint256[] calldata batchesAmount,
        RouterPath[][] calldata batches,
        PMMLib.PMMSwapRequest[] calldata extraData,
        address payer,
        address receiver
    ) external payable returns (uint256 returnAmount);

  }
