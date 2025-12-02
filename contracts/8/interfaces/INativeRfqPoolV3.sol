// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INativeRfqPoolV3 {
    struct PermitTransferFrom {
        TokenPermissions permitted;
        uint256 nonce;
        uint256 deadline;
    }

    struct TokenPermissions {
        address token;
        uint256 amount;
    }
    struct PermitQuote {
        address swapper;
        address marketMaker;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        address recipient;
        address pool;
        uint256 nonce;
        uint256 deadline;
        bytes signature;
        bytes orderBookSig;
        bytes32 orderBookDigest;
        WidgetFee widgetFee;
    }

    struct RFQTQuote {
        /// @notice RFQ pool address
        address pool;
        /// @notice market maker
        address signer;
        /// @notice The recipient of the buyerToken at the end of the trade.
        address recipient;
        /// @notice The token that the trader sells.
        address sellerToken;
        /// @notice The token that the trader buys.
        address buyerToken;
        /// @notice The max amount of sellerToken sold.
        uint256 sellerTokenAmount;
        /// @notice The amount of buyerToken bought when sellerTokenAmount is sold.
        uint256 buyerTokenAmount;
        /// @notice Minimum buyerToken amount received
        uint256 amountOutMinimum;
        /// @notice The Unix timestamp (in seconds) when the quote expires.
        uint256 deadlineTimestamp;
        /// @notice Nonces are used to protect against replay.
        uint256 nonce;
        /// @notice confidence control factor T
        uint256 confidenceExtractedValueT;
        /// @notice confidence control factor N
        uint256 confidenceExtractedValueN;
        /// @notice confidence control factor E
        uint256 confidenceExtractedValueE;
        /// @notice confidence control factor M
        uint256 confidenceExtractedValueM;
        /// @notice Unique identifier for the quote.
        /// @dev Generated off-chain via a distributed UUID generator.
        bytes16 quoteId;
        /// @dev  false if this quote is for the 1st hop of a multi-hop or a single-hop, in which case msg.sender is the payer.
        ///       true if this quote is for 2nd or later hop of a multi-hop, in which case router is the payer.
        bool multiHop;
        /// @notice Signature provided by the market maker (EIP-191).
        bytes signature;
        /// @notice Widget fee information
        WidgetFee widgetFee;
        /// @notice Widget fee signature
        bytes widgetFeeSignature;
    }

    struct WidgetFee {
        address feeRecipient;
        uint256 feeRate;
    }
    error ArraysLengthMismatch();
    error ExternalCallFailed(address target, bytes4 selector);
    error InsufficientWETH9();
    error InvalidAmount();
    error InvalidNativePool();
    error InvalidShortString();
    error InvalidSignature();
    error InvalidWidgetFeeRate();
    error NotEnoughAmountOut(uint256 amountOut, uint256 amountOutMinimum);
    error NotEnoughTokenReceived();
    error OnlyWETH9();
    error OrderExpired();
    error Permit2TokenMismatch();
    error QuoteExpired();
    error ReentrancyGuardReentrantCall();
    error StringTooLong(string str);
    error UnexpectedMsgValue();
    error ZeroAddress();
    error ZeroAmount();

    event EIP712DomainChanged();
    event ExternalSwapExecuted(
        address externalRouter,
        address sender,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        bytes16 quoteId
    );
    event NativePoolUpdated(address indexed pool, bool isActive);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Paused(address account);
    event RefundERC20(address token, address recipient, uint256 amount);
    event RefundETH(address recipient, uint256 amount);
    event SignerUpdated(address signer, bool isSigner);
    event Unpaused(address account);
    event UnwrapWETH9(address indexed recipient, uint256 amount);
    event WhitelistRouterSet(address indexed router, bool isWhitelisted);
    event WidgetFeeTransfer(
        address widgetFeeRecipient,
        uint256 widgetFeeRate,
        uint256 widgetFeeAmount,
        address widgetFeeToken
    );
    event WidgetFeesWithdrawn(
        address indexed recipient,
        address token,
        uint256 amount
    );

    receive() external payable;

    function WETH9() external view returns (address);
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
    function fillOrder(
        PermitQuote memory quote,
        PermitTransferFrom memory swapperPermit,
        bytes memory swapperSig
    ) external;
    function isNativePools(address) external view returns (bool);
    function multicall(
        uint256 deadline,
        bytes[] memory data
    ) external payable returns (bytes[] memory);
    function multicall(
        bytes[] memory data
    ) external payable returns (bytes[] memory results);
    function owner() external view returns (address);
    function pause() external;
    function paused() external view returns (bool);
    function refundERC20(
        address token,
        address recipient,
        uint256 amount
    ) external payable;
    function refundETH(address recipient, uint256 amount) external payable;
    function renounceOwnership() external;
    function setNativePool(address pool, bool isActive) external;
    function setSigner(address signer, bool isSigner) external;
    function setWhitelistRouter(
        address[] memory routers,
        bool[] memory values
    ) external;
    function signers(address) external view returns (bool);
    function tradeRFQT(RFQTQuote memory quote) external payable;
    function tradeRFQT(
        RFQTQuote memory quote,
        uint256 actualSellerAmount,
        uint256 actualMinOutputAmount
    ) external payable;
    function transferOwnership(address newOwner) external;
    function unpause() external;
    function unwrapWETH9(address recipient) external payable;
    function vault() external view returns (address);
    function whitelistRouter(address) external view returns (bool);
}
