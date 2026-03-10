// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IApprove {
    function claimTokens(
        address token,
        address who,
        address dest,
        uint256 amount
    ) external;
}
