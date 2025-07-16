// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDODOV2} from "../interfaces/IDODOV2.sol";
import {IAdapter} from "../interfaces/IAdapter.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";


contract DODOV2Adapter is IAdapter {
    function sellBase(
        address to,
        address pool,
        bytes memory
    ) external override {
        IDODOV2(pool).sellBase(to);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory
    ) external override {
        IDODOV2(pool).sellQuote(to);
    }
}
