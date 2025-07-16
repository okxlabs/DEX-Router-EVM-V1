// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISynthetix.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract SynthetixExchangeWithTrackingAdapter is IAdapter {

    bytes32 constant TRACKINGCODE = "XROUTER";// "XROUTER" to bytes32:0x58524f5554455200000000000000000000000000000000000000000000000000
    address public immutable SNX_PROXY; //op:0x8700daec35af8ff88c16bdf0418774cb3d7599b4

    constructor(address _snxproxy) {
        SNX_PROXY = _snxproxy;
    }

    function _synthetixExchangeWithTracking(
        address to,
        address ,
        bytes memory moreInfo
    ) internal {
        (bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey, address fromToken, address toToken) = abi.decode(
            moreInfo,
            (bytes32, bytes32, address, address)
        );
        ISNXPROXY(SNX_PROXY).exchangeWithTracking(
            sourceCurrencyKey,
            IERC20(fromToken).balanceOf(address(this)),
            destinationCurrencyKey,
            to,
            TRACKINGCODE
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
        _synthetixExchangeWithTracking(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _synthetixExchangeWithTracking(to, pool, moreInfo);
    }

}
