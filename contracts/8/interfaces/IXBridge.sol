// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

interface IXBridge {
    function payerReceiver() external view returns(address, address);
}
