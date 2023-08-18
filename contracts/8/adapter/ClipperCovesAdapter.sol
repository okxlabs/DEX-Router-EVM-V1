// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IClipperExchangeInterface.sol";

import "../interfaces/IAdapter.sol";
import "../interfaces/IClipperCove.sol";

contract ClipperCovesAdapter is IAdapter {

    function _clippeCovesrSwap(
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
        _clippeCovesrSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _clippeCovesrSwap(to, pool, moreInfo);
    }
}
