// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IEtherFiLP {
    /// @notice The eETH token contract
    function eETH() external view returns (address);

    /// @notice Deposit ETH to the pool
    /// @return Returns the amount of shares minted
    function deposit() external payable returns (uint256);

    /// @notice Deposit ETH to the pool with referral
    /// @param _referral The referral address
    /// @return Returns the amount of shares minted
    function deposit(address _referral) external payable returns (uint256);

    /// @notice Deposit to a specific recipient
    /// @param _recipient The recipient address
    /// @param _amount The amount to deposit
    /// @param _referral The referral address
    /// @return Returns the amount of shares minted
    function depositToRecipient(
        address _recipient,
        uint256 _amount,
        address _referral
    ) external returns (uint256);

    /// @notice Deposit on behalf of a user (for ether.fan)
    /// @param _user The user address
    /// @param _referral The referral address
    /// @return Returns the amount of shares minted
    function deposit(
        address _user,
        address _referral
    ) external payable returns (uint256);

    /// @notice Withdraw from pool
    /// @param _recipient The recipient who will receive the ETH
    /// @param _amount The amount to withdraw
    /// @return Returns the amount of shares burned
    function withdraw(
        address _recipient,
        uint256 _amount
    ) external returns (uint256);

    /// @notice Request withdrawal from pool
    /// @param recipient The address that will receive the NFT
    /// @param amount The requested amount to withdraw
    /// @return Returns the requestId of the WithdrawRequestNFT
    function requestWithdraw(
        address recipient,
        uint256 amount
    ) external returns (uint256);
}
