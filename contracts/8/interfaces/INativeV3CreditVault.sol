// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INativeV3CreditVault {
    function lpTokens(address underlyingToken) external view returns (address);
}
