pragma solidity ^0.8.0;
pragma abicoder v2;

interface ISparkPsm {

    function rateProvider() external view returns (address);

    function swapExactIn(
        address assetIn,
        address assetOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        uint256 referralCode
    ) external returns (uint256 amountOut);

}
