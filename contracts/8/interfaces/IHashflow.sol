/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;


struct IQuote {
    address pool;
    address externalAccount;
    address trader;
    address effectiveTrader;
    address baseToken;
    address quoteToken;
    uint256 effectiveBaseTokenAmount;
    uint256 maxBaseTokenAmount;
    uint256 maxQuoteTokenAmount;
    uint256 quoteExpiry;
    uint256 nonce;
    bytes32 txid;
    bytes signedQuote;
}


interface IHashflow {
    function tradeSingleHop(
        IQuote memory rpcStruct
    ) external payable;
}