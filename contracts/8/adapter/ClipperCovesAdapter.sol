// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IClipperExchangeInterface.sol";

import "../interfaces/IAdapter.sol";
import "../interfaces/IClipperCove.sol";

contract ClipperCovesAdapter is IAdapter {
    // Notes: The current quoting system does not support the exchange of Clipper LP tokens and underlying assets. Please be aware of the risks.
    // If support for LP token and underlying asset exchange is required, a new adapter will be used.
    function _clipperCovesSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address sellToken, address buyToken) = abi.decode(moreInfo, (address ,address));
        IClipperCove(pool).sellTokenForToken(
            sellToken,
            buyToken,
            0,
            to,
            0x0
        );
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _clipperCovesSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _clipperCovesSwap(to, pool, moreInfo);
    }
}
