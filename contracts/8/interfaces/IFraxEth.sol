/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IfrxETHMinter {

    /// @notice Mint frxETH to the recipient using sender's funds
    function submitAndGive(address recipient) external payable;

    /// @notice Mint frxETH and deposit it to receive sfrxETH in one transaction
    /** @dev Could try using EIP-712 / EIP-2612 here in the future if you replace this contract,
        but you might run into msg.sender vs tx.origin issues with the ERC4626 */
    function submitAndDeposit(address recipient) external payable returns (uint256 shares);
}


interface IsfrxETH {

    // frxETH => sfrxETH
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    // sfrxETH => frxETH
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}