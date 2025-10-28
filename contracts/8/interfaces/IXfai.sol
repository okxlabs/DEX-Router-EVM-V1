// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IXfaiPool {

    function getStates() external view returns (uint, uint);
}

interface IXfaiCore {
    
    function swap(
       address _token0,
       address _token1,
       address _to
    ) external returns (uint input, uint output);
}