// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISynthetix.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract SynthetixExchangeAtomicallyAdapter is IAdapter {

    uint256 constant MIN_RETURN = 0;
    bytes32 constant TRACKINGCODE = "XROUTER";// "XROUTER" to bytes32:0x58524f5554455200000000000000000000000000000000000000000000000000
    address public immutable SNX_PROXY;

    constructor(address _snxproxy) {
        SNX_PROXY = _snxproxy;
    }

    function _synthetixExchangeAtomically(
        address to,
        address ,
        bytes memory moreInfo
    ) internal {
        (bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey, address fromToken, address toToken) = abi.decode(
            moreInfo,
            (bytes32, bytes32, address, address)
        );
        ISNXPROXY(SNX_PROXY).exchangeAtomically(
            sourceCurrencyKey,
            IERC20(fromToken).balanceOf(address(this)),
            destinationCurrencyKey,
            TRACKINGCODE,
            MIN_RETURN
        );
        SafeERC20.safeTransfer(
            IERC20(toToken),
            to,
            IERC20(toToken).balanceOf(address(this))
        );

    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _synthetixExchangeAtomically(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _synthetixExchangeAtomically(to, pool, moreInfo);
    }

}
