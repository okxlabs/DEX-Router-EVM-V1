// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "./IERC20.sol";

interface IAllBridge {

    function swap(
        uint amount,
        bytes32 token,
        bytes32 receiveToken,
        address recipient,
        uint receiveAmountMin
    ) external;
}
