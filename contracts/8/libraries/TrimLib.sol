/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/AbstractTrimLib.sol";
import "./CommonLib.sol";
import "./CommissionLib.sol";

abstract contract TrimLib is AbstractTrimLib, CommonLib, CommissionLib {
    uint256 internal constant _TRIM_FLAG_MASK =
        0xffffffffffff0000000000000000000000000000000000000000000000000000;
    uint256 internal constant _TRIM_EXPECT_AMOUNT_MASK =
        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant _TRIM_RATE_MASK =
        0x000000000000ffffffffffff0000000000000000000000000000000000000000;
    uint256 internal constant _TRIM_ADDRESS_MASK =
        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant TRIM_FLAG =
        0x7777777711110000000000000000000000000000000000000000000000000000;
    uint256 internal constant TRIM_DUAL_FLAG =
        0x7777777722220000000000000000000000000000000000000000000000000000;

    function _getTrimInfo(uint256 offset)
        internal
        pure
        override
        returns (TrimInfo memory trimInfo)
    {
        assembly ("memory-safe") {
            function _revertWithReason(m, len) {
                mstore(
                    0,
                    0x08c379a000000000000000000000000000000000000000000000000000000000
                )
                mstore(
                    0x20,
                    0x0000002000000000000000000000000000000000000000000000000000000000
                )
                mstore(0x40, m)
                revert(0, len)
            }

            let trimFlag := 0
            // get first flag, if not one of the flags, then return; otherwise get trim rate and address
            let trimData := calldataload(sub(calldatasize(), add(offset, 32)))
            let flag := and(trimData, _TRIM_FLAG_MASK)
            switch or(eq(flag, TRIM_FLAG), eq(flag, TRIM_DUAL_FLAG))
            case 1 {
                trimFlag := flag
                mstore(trimInfo, 1)
                mstore(
                    add(0x20, trimInfo),
                    shr(160, add(trimData, _TRIM_RATE_MASK))
                )
                mstore(
                    add(0x40, trimInfo),
                    add(trimData, _TRIM_ADDRESS_MASK)
                )
            }
            default {
                // clear trimInfo and return
                for { let i := 0 } lt(i, 6) { i := add(i, 1) } {
                    mstore(add(trimInfo, mul(i, 0x20)), 0)
                }
                return(trimInfo, 0xc0)
            }
            // get second flag, if the same as first flag, then get expect amount; otherwise revert
            trimData := calldataload(sub(calldatasize(), add(offset, 64)))
            flag := and(trimData, _TRIM_FLAG_MASK)
            if eq(eq(flag, trimFlag), 0) {
                // encoded trim flag mismatch, then revert
                _revertWithReason(
                    0x000000127472696d20666c6167206d69736d617463680000000000000000000000, // "trim flag mismatch"
                    0x56
                )
            }
            mstore(
                add(0x60, trimInfo),
                and(trimData, _TRIM_EXPECT_AMOUNT_MASK)
            )
            switch eq(trimFlag, TRIM_DUAL_FLAG)
            case 1 {
                // get third flag, if the same as first flag, then get trim rate2 and address2; otherwise revert
                trimData := calldataload(sub(calldatasize(), add(offset, 96)))
                flag := and(trimData, _TRIM_FLAG_MASK)
                if eq(eq(flag, trimFlag), 0) {
                    // encoded trim flag mismatch, then revert
                    _revertWithReason(
                        0x000000127472696d20666c6167206d69736d617463680000000000000000000000, // "trim flag mismatch"
                        0x56
                    )
                }
                mstore(
                    add(0x80, trimInfo),
                    shr(160, add(trimData, _TRIM_RATE_MASK))
                )
                mstore(
                    add(0xa0, trimInfo),
                    add(trimData, _TRIM_ADDRESS_MASK)
                )
            }
            default {
                mstore(add(0x80, trimInfo), 0)
                mstore(add(0xa0, trimInfo), 0)
            }
        }
    }

    function _doTrimToToken(
        TrimInfo memory trimInfo,
        address receiver,
        address token,
        uint256 balanceBefore
    ) internal override returns (uint256 trimAmount) {
        if (!trimInfo.hasTrim) {
            return 0;
        }
        require(trimInfo.trimRate > 0, "trim rate must be > 0");
        require(trimInfo.trimRate + trimInfo.trimRate2 <= 100, "total trim rate must be <= 100");

        uint256 actualAmount = _getBalanceOf(token, address(this)) - balanceBefore;
        if (actualAmount > trimInfo.expectAmountOut) {
            uint256 surplusAmount = actualAmount - trimInfo.expectAmountOut;
            uint256 allowedMaxTrimAmount = actualAmount * (trimInfo.trimRate + trimInfo.trimRate2) / 1000;
            trimAmount = surplusAmount > allowedMaxTrimAmount ? allowedMaxTrimAmount : surplusAmount;
            if (trimInfo.trimRate2 == 0) {
                _transferTokenTo(token, trimInfo.trimAddress, trimAmount);
            } else {
                uint256 trimAmount1 = trimAmount * trimInfo.trimRate / (trimInfo.trimRate + trimInfo.trimRate2);
                _transferTokenTo(token, trimInfo.trimAddress, trimAmount1);
                _transferTokenTo(token, trimInfo.trimAddress2, trimAmount - trimAmount1);
            }
        }
        _transferTokenTo(token, receiver, actualAmount - trimAmount);
    }
}