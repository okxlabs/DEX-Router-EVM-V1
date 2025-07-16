/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDODOV3 {
    // =============== Read ===============
    function getTokenMMPriceInfoForRead(address token)
        external 
        view
        returns (
            uint256 askDownPrice,
            uint256 askUpPrice,
            uint256 bidDownPrice,
            uint256 bidUpPrice,
            uint256 swapFee
        );

    function getTokenMMOtherInfoForRead(address token)
        external
        view
        returns (
            uint256 askAmount,
            uint256 bidAmount,
            uint256 kAsk,
            uint256 kBid,
            uint256 cumulativeAsk,
            uint256 cumulativeBid
        );

    // ============ Swap =============
    /// @notice user sell a certain amount of fromToken,  get toToken
    function sellToken(
        address to,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minReceiveAmount,
        bytes calldata data
    ) external returns (uint256);

    /// @notice user ask for a certain amount of toToken, fromToken's amount will be determined by toToken's amount
    function buyToken(
        address to,
        address fromToken,
        address toToken,
        uint256 quoteAmount,
        uint256 maxPayAmount,
        bytes calldata data
    ) external returns (uint256);

    /// @notice user could query sellToken result deducted swapFee, assign fromAmount
    /// @return payFromAmount fromToken's amount = fromAmount
    /// @return receiveToAmount toToken's amount
    /// @return vusdAmount fromToken bid vusd
    /// @return swapFee dodo takes the fee
    function querySellTokens(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (
        uint256 payFromAmount,
        uint256 receiveToAmount,
        uint256 vusdAmount,
        uint256 swapFee,
        uint256 mtFee
    );

    /// @notice user could query sellToken result deducted swapFee, assign toAmount
    /// @return payFromAmount fromToken's amount
    /// @return receiveToAmount toToken's amount = toAmount
    /// @return vusdAmount fromToken bid vusd
    /// @return swapFee dodo takes the fee 
    function queryBuyTokens(
        address fromToken,
        address toToken,
        uint256 toAmount
    ) external view returns (
        uint256 payFromAmount,
        uint256 receiveToAmount,
        uint256 vusdAmount,
        uint256 swapFee,
        uint256 mtFee
    );

}