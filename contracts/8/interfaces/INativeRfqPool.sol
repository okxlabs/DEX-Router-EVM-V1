// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INativeRfqPool {
    struct WidgetFee {
        address signer;
        address feeRecipient;
        uint256 feeRate;
    }
    struct RFQTQuote {
        address pool;
        address signer;
        address recipient;
        address sellerToken;
        address buyerToken;
        uint256 effectiveSellerTokenAmount;
        uint256 sellerTokenAmount;
        uint256 buyerTokenAmount;
        uint256 deadlineTimestamp;
        uint256 nonce;
        bytes16 quoteId;
        bool multiHop;
        bytes signature;
        WidgetFee widgetFee;
        bytes widgetFeeSignature;
        bytes externalSwapCalldata;
        uint amountOutMinimum;
    }

    function tradeRFQT(RFQTQuote memory quote) external payable;

    event SignerUpdated(address signer, bool value);
    event OwnerSet(address owner);
    event TreasurySet(address treasury);
    event PostTradeCallbackSet(bool value);
    event PauseSet(bool value);
    event RfqTrade(
        address recipient,
        address sellerToken,
        address buyerToken,
        uint256 sellerTokenAmount,
        uint256 buyerTokenAmount,
        bytes16 quoteId,
        address signer
    );

    error InvalidNewImplementation();
    error CallerNotFactory();
    error CallerNotRouter();
    error CallerNotOwner();
    error CallerNotPendingOwner();
    error ZeroOrEmptyInput();
    error TradePaused();
    error NonceUsed();
    error InvalidSigner();
    error InvalidSignature();
    error Overflow();
}
