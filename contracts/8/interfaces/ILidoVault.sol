// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILidoVault {

    function decimals() external view returns (uint8);

    //return the amount of tokens owned by the _account
    function balanceOf(address _account) external view returns (uint256);

    //return the amount of shares owned by the _account
    function sharesOf(address _account) external view returns (uint256);
    
    //amountToShare
    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);

    //shareToAmount
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    function getFee() external view returns (uint16);

    function isStakingPaused() external view returns (bool);

    function getCurrentStakeLimit() external view returns (uint256);

    //_amount tokens from the caller's account to the _recipient account
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    //returns amount of transferred tokens
    function transferShares(address _recipient, uint256 _shareAmount) external returns (uint256);

    //deposit native token
    function submit(address _referral) external payable returns (uint256);

    //Matic -> stMatic
    //amountToShare, returns balanceInStMatic, totalShares, totalPooledMatic
    function convertMaticToStMatic(uint256 _balance) external view returns (uint256, uint256, uint256);
    //shareToAmount, returns balanceInMatic, totalShares, totalPooledMatic
    function convertStMaticToMatic(uint256 _balance) external view returns (uint256, uint256, uint256);

    //stETH <-> wstETH
    //shareToAmount
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    //amountToShare
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
    //deposit
    function wrap(uint256 _stETHAmount) external returns (uint256);
    //withdraw
    function unwrap(uint256 _wstETHAmount) external returns (uint256);

}

interface ILidoVaultMatic {
    //send funds to StMatic contract and mints StMatic to msg.sender, return amount of StMatic shares generated
    function submit(uint256 _amount, address _referral) external returns (uint256);

}