// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IEtherFiLP {
    function eETH() external view returns (address);

    function deposit() external payable returns (uint256);

    function deposit(address _referral) external payable returns (uint256);

    function depositToRecipient(
        address _recipient,
        uint256 _amount,
        address _referral
    ) external returns (uint256);

    function deposit(
        address _user,
        address _referral
    ) external payable returns (uint256);

    function withdraw(
        address _recipient,
        uint256 _amount
    ) external returns (uint256);

    function requestWithdraw(
        address recipient,
        uint256 amount
    ) external returns (uint256);
}
