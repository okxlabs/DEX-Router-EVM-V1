pragma solidity 0.8.17;
pragma abicoder v2;

struct RFQTQuote {
    address pool;
    address externalAccount;
    address trader;
    address effectiveTrader;
    address baseToken;
    address quoteToken;
    uint256 effectiveBaseTokenAmount;
    uint256 baseTokenAmount;
    uint256 quoteTokenAmount;
    uint256 quoteExpiry;
    uint256 nonce;
    bytes32 txid;
    bytes signature;
}

interface IHashflowV3 {
    function tradeRFQT(
        RFQTQuote memory rpcStruct
    ) external payable;
}
