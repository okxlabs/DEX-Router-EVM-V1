// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct SellParams {
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint256 amountOutMin;
    bool wrapUnwrap;
    address to;
    //uint256 gasLimit;
    uint32 submitDeadline;
}
interface ITwapDelay {

    function sell(SellParams memory sellParams) external payable returns (uint256 orderId);
}

interface ITwapRelay {

    function sell(SellParams memory sellParams) external payable returns (uint256 orderId);
}

interface ITwapPair {
    function oracle() external view returns (address);
}

interface ITwapOracle{
    function getPriceInfo() external view returns (uint256 priceAccumulator, uint32 priceTimestamp);
}