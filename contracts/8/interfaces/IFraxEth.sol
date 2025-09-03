pragma solidity ^0.8.0;
pragma abicoder v2;

interface IfrxETHMinter {

    function submitAndGive(address recipient) external payable;

    function submitAndDeposit(address recipient) external payable returns (uint256 shares);
}

interface IsfrxETH {

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}
