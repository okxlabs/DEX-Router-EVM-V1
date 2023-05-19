// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IPmmRFQ.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "hardhat/console.sol";

contract PmmRFQAdapter is IAdapter {
    uint256 private constant _SIGNER_SMART_CONTRACT_HINT = 1 << 254;
    uint256 private constant _IS_VALID_SIGNATURE_65_BYTES = 1 << 253;
    uint256 private constant _UNWRAP_WETH_FLAG = 1 << 252;
    uint256 private constant _SETTLE_FLAG = 1 << 251;
    address public immutable PMMRFQ_ADDRESS;

    constructor(address _pmmRFQ) {
        PMMRFQ_ADDRESS = _pmmRFQ;
    }

    function _fillOrderRFQTo(address to, bytes memory moreInfo) internal {
        (
            OrderRFQ memory order,
            bytes memory signature,
            uint256 flagsAndAmount
        ) = abi.decode(moreInfo, (OrderRFQ, bytes, uint256));

        address fromToken = order.takerAsset;
        uint256 fromAmount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), PMMRFQ_ADDRESS, fromAmount);

        if (flagsAndAmount & _SIGNER_SMART_CONTRACT_HINT != 0) {
            fromAmount = _SIGNER_SMART_CONTRACT_HINT | fromAmount;
        }
        if (flagsAndAmount & _IS_VALID_SIGNATURE_65_BYTES != 0) {
            fromAmount = _IS_VALID_SIGNATURE_65_BYTES | fromAmount;
        }
        if (flagsAndAmount & _UNWRAP_WETH_FLAG != 0) {
            fromAmount = _UNWRAP_WETH_FLAG | fromAmount;
        }
        if (flagsAndAmount & _SETTLE_FLAG != 0) {
            fromAmount = _SETTLE_FLAG | fromAmount;
        }
        IPmmRFQ(PMMRFQ_ADDRESS).fillOrderRFQTo(
            order,
            signature,
            fromAmount,
            to
        );
    }

    function sellBase(
        address to,
        address,
        bytes memory moreInfo
    ) external override {
        _fillOrderRFQTo(to, moreInfo);
    }

    function sellQuote(
        address to,
        address,
        bytes memory moreInfo
    ) external override {
        _fillOrderRFQTo(to, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}
