// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IXfai.sol";
import "../interfaces/IERC20.sol";

/// @title XfaiAdapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract XfaiAdapter is IAdapter {

    address constant XFETH_ADDRESS = 0xa449845c3309ac5269DFA6b2F80eb6E73D0AE021;
    address constant XFAIV0CORE_ADDRESS = 0xCC4fCe9171dE972aE892BD0b749F96B49b3740E7;

    // fromToken == token
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        address quoteToken = XFETH_ADDRESS;
        (uint256 reserveIn, uint256 reserveOut) = IXfaiPool(pool).getStates();
        address baseToken= abi.decode( moreInfo, (address));
        require(
            reserveIn > 0 && reserveOut > 0,
            "XfaiAdapter: INSUFFICIENT_LIQUIDITY"
        );


        IXfaiCore(XFAIV0CORE_ADDRESS).swap(baseToken, quoteToken, to);
    }

    // fromToken == xfeth
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        address quoteToken = XFETH_ADDRESS;
        (uint256 reserveOut, uint256 reserveIn) = IXfaiPool(pool).getStates();
        (address baseToken)= abi.decode( moreInfo, (address));
        require(
            reserveIn > 0 && reserveOut > 0,
            "XfaiAdapter: INSUFFICIENT_LIQUIDITY"
        );

        IXfaiCore(XFAIV0CORE_ADDRESS).swap(quoteToken, baseToken, to);
    }
}