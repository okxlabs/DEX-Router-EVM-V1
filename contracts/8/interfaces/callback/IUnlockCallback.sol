// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUnlockCallback {
    function unlockCallback(bytes calldata data) external returns (bytes memory);
}
