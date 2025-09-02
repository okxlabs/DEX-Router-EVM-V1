// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Abstract base contract with virtual functions
abstract contract AbstractTrimLib {
    struct TrimInfo {
        bool hasTrim; // 0x00
        uint256 trimRate; // 0x20
        address trimAddress; // 0x40
        uint256 expectAmountOut; // 0x60
        uint256 trimRate2; // 0x80
        address trimAddress2; // 0xa0
    }

    event PositiveSlippageTrimRecord(
        address toTokenAddress,
        uint256 trimRate,
        uint256 trimAmount,
        address trimAddress,
        uint256 expectAmountOut,
        uint256 actualAmount
    );

    function _getTrimInfo(uint256 offset)
        internal
        pure
        virtual
        returns (TrimInfo memory trimInfo);

    function _doTrimToToken(
        TrimInfo memory trimInfo,
        address receiver,
        address token,
        uint256 balanceBefore
    ) internal virtual returns (uint256);
}
