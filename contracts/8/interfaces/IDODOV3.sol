pragma solidity 0.8.17;

interface IDODOV3 {
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

    function sellToken(
        address to,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minReceiveAmount,
        bytes calldata data
    ) external returns (uint256);

    function buyToken(
        address to,
        address fromToken,
        address toToken,
        uint256 quoteAmount,
        uint256 maxPayAmount,
        bytes calldata data
    ) external returns (uint256);

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
