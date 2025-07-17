// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IGmxVault.sol";

contract GmxAdapter is IAdapter {

    function _gmxSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address sourceToken, address targetToken) = abi.decode(
            moreInfo,
            (address, address)
        );
        IGmxVault(pool).swap(sourceToken, targetToken, to);
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _gmxSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _gmxSwap(to, pool, moreInfo);
    }

}
