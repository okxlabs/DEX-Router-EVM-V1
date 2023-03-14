// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IPSM {
    function buyGem(address usr, uint256 gemAmt) external;

    function sellGem(address usr, uint256 gemAmt) external;

    function tin() external view returns (uint256);
    function tout() external view returns (uint256);
}
