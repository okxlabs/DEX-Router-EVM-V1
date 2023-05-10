/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;




interface IAaveLendingPool {

    // token => atoken
    function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
    ) external;
    // atoken => token
    function withdraw(
    address asset,
    uint256 amount,
    address to
    ) external returns (uint256);

}
