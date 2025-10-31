// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICTokenV3 {
    function supplyTo(address dst, address asset, uint amount)  external;
    function withdrawTo( address to, address asset, uint amount) external;
}
