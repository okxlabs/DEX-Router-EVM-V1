// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILidoVault {

    function decimals() external view returns (uint8);

    function balanceOf(address _account) external view returns (uint256);

    function sharesOf(address _account) external view returns (uint256);
    
    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);

    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    function getFee() external view returns (uint16);

    function isStakingPaused() external view returns (bool);

    function getCurrentStakeLimit() external view returns (uint256);

    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function transferShares(address _recipient, uint256 _shareAmount) external returns (uint256);

    function submit(address _referral) external payable returns (uint256);

    function convertMaticToStMatic(uint256 _balance) external view returns (uint256, uint256, uint256);
    function convertStMaticToMatic(uint256 _balance) external view returns (uint256, uint256, uint256);

    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);

}

interface ILidoVaultMatic {
    function submit(uint256 _amount, address _referral) external returns (uint256);

}
