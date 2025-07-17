// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/ITraderJoeV2P2.sol";

contract TraderJoeV2P2Adapter is IAdapter {
    // fromToken == tokenX
    function sellBase(
        address to,
        address pool,
        bytes memory 
    ) external override {
        ILBPair(pool).swap(false, to);
    }

    // fromToken == tokenY
    function sellQuote(
        address to,
        address pool,
        bytes memory 
    ) external override {
        ILBPair(pool).swap(true, to);
    }
}
