// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISyncSwap {
    /// @dev Swaps between to
    struct TokenAmount {
        address token;
        uint amount;
    }

    function swap(
        bytes calldata data,
        address sender,
        address callback,
        bytes calldata callbackData
    ) external returns (TokenAmount memory tokenAmount);
}

interface IVault {
    function wETH() external view returns (address);

    function reserves(address token) external view returns (uint reserve);

    function balanceOf(address token, address owner) external view returns (uint balance);

    function deposit(address token, address to) external payable returns (uint amount);

    function depositETH(address to) external payable returns (uint amount);

    function transferAndDeposit(address token, address to, uint amount) external payable returns (uint);

    function transfer(address token, address to, uint amount) external;

    function withdraw(address token, address to, uint amount) external;

    function withdrawAlternative(address token, address to, uint amount, uint8 mode) external;

    function withdrawETH(address to, uint amount) external;
}