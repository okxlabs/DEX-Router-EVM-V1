/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
interface IAnyToken {
    function withdraw() external returns (uint);
    function underlying() external returns (address);
}