// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ILendingPool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
    
    function deposit(
      address asset,
      uint256 amount,
      address onBehalfOf,
      uint16 referralCode
    ) external;
}
