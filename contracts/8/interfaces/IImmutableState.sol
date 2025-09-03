// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolManager} from "./IPoolManager.sol";

interface IImmutableState {
    function poolManager() external view returns (IPoolManager);
}
