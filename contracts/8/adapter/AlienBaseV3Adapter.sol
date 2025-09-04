// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./UniV3Adapter.sol";

contract AlienBaseV3Adapter is UniV3Adapter {
    constructor(address payable weth) UniV3Adapter(weth) {}
}
