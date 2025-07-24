/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface ITokenManager2 {

    function buyTokenAMAP(
        address token,
        address to, 
        uint256 funds, 
        uint256 minAmount
    ) external payable;

    function sellToken(
        address token, 
        uint256 amount
    ) external;

    function sellToken(
        uint256 origin, //The platform from which the request is sent. Pass 0 if not applicable.
        address token, //The address of the token to be sold.
        address from, //The address of the token owner(tx.orgin == from).
        uint256 amount, //The amount of tokens to be sold.
        uint256 minFunds, //The minimum amount of funds to be received after the sale.
        uint256 feeRate, //The router’s fee rate. 100 means 1%, and 10 means 0.1%. (MAX 5%)
        address feeRecipient//The address that will receive the fee.
    ) external;
}
