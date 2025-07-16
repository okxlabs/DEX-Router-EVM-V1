/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;




interface IRocketDepositPool {

    // ETH => rETH
    function deposit() external payable;
}
interface IRETH {
    // rETH => ETH
    function burn(uint256 _rethAmount) external;
}