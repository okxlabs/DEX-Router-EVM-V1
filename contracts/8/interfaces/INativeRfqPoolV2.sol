// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INativeRfqPoolV2 {
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
        address pool;
        address signer;
        address recipient;
        address sellerToken;
        address buyerToken;
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
        uint256 amountOutMinimum;
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
    function transferOwnership(address newOwner) external;
    function unpause() external;
    function unwrapWETH9(address recipient) external payable;
    function vault() external view returns (address);
    function whitelistRouter(address) external view returns (bool);
}
