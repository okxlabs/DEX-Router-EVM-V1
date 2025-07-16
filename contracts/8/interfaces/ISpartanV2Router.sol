// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface ISpartanV2Router {
    function buyTo(
        uint amount,
        address token,
        address member,
        uint minAmount
    ) external ;
    
    function sellTo(
        uint amount,
        address token,
        address member,
        uint minAmount,
        bool yesDiv
    ) external payable returns (uint);

}

