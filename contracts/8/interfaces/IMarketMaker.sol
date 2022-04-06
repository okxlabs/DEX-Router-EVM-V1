/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketMaker{

  struct PMMSwapRequest {
    uint256 pathIndex;
    address payer;
    address fromToken;
    address toToken;
    uint256 fromTokenAmountMax;
    uint256 toTokenAmountMax;
    uint256 salt;
    uint256 deadLine;
    bool    isPushOrder;
  }

  function swap(
      address to,                 
      uint256 actualAmountRequest,  
      PMMSwapRequest memory pmmRequest,
      bytes memory signature
  ) external returns(bool);
}