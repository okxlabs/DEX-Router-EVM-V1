/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IAdapterWithResult {
    function sellBase(
        address to,
        address pool,
        bytes memory data
    ) external returns (uint256 errorCode);

    function sellQuote(
        address to,
        address pool,
        bytes memory data
    ) external returns (uint256 errorCode);
}
