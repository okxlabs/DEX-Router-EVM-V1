// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IWooPPV2 {

    event Deposit(address indexed token, address indexed sender, uint256 amount);
    event Withdraw(address indexed token, address indexed receiver, uint256 amount);
    event AdminUpdated(address indexed addr, bool flag);
    event FeeManagerUpdated(address indexed newFeeManager);
    event WooracleUpdated(address indexed newWooracle);
    event WooSwap(
        address indexed fromToken,
        address indexed toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address from,
        address indexed to,
        address rebateTo
    );

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address to,
        address rebateTo
    ) external returns (uint256 realToAmount);

    function sellBase(
        address baseToken,
        uint256 baseAmount,
        uint256 minQuoteAmount,
        address to,
        address rebateTo
    ) external returns (uint256 quoteAmount);

    function sellQuote(
        address baseToken,
        uint256 quoteAmount,
        uint256 minBaseAmount,
        address to,
        address rebateTo
    ) external returns (uint256 baseAmount);

    function querySellBase(address baseToken, uint256 baseAmount) external view returns (uint256 quoteAmount);

    function querySellQuote(address baseToken, uint256 quoteAmount) external view returns (uint256 baseAmount);

    function quoteToken() external view returns (address);
}
