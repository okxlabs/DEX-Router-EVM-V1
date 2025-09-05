// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TrimHelper {
    uint256 internal constant TRIM_FLAG =
        0x7777777711110000000000000000000000000000000000000000000000000000;
    uint256 internal constant TRIM_DUAL_FLAG =
        0x7777777722220000000000000000000000000000000000000000000000000000;

    /*
     *  Trim data should be encoded after method calldata and before commission data, the size may be 64 or 96 bytes.
     *  Single Trim:
     *  ┌─────────────┬─────────────┬─────────────────┬─────────────┬─────────────┬─────────────────┐
     *  │ trim_flag   │ padding     │ expect_amount   │ trim_flag   │ trim_rate   │ trim_address    │
     *  │ 6 bytes     │ 6 bytes     │ 20 bytes        │ 6 bytes     │ 6 bytes     │ 20 bytes        │
     *  │0x777777771111│0x000000000000│               │0x777777771111│            │                 │
     *  └─────────────┴─────────────┴─────────────────┴─────────────┴─────────────┴─────────────────┘
     *  ←──────────────--- 32 bytes ---──────────────→ ←──────────────--- 32 bytes ---──────────────→
     *  Dual Trim:
     *  ┌─────────────┬─────────────┬─────────────────┬─────────────┬─────────────┬─────────────────┬─────────────┬─────────────┬─────────────────┐
     *  │ trim_flag   │ trim_rate2  │ trim_address2   │ trim_flag   │ padding     │ expect_amount   │ trim_flag   │ trim_rate1  │ trim_address1   │
     *  │ 6 bytes     │ 6 bytes     │ 20 bytes        │ 6 bytes     │ 6 bytes     │ 20 bytes        │ 6 bytes     │ 6 bytes     │ 20 bytes        │
     *  │0x777777772222│            │                 │0x777777772222│0x000000000000│               │0x777777772222│            │                 │
     *  └─────────────┴─────────────┴─────────────────┴─────────────┴─────────────┴─────────────────┴─────────────┴─────────────┴─────────────────┘
     *  ←──────────────--- 32 bytes ---──────────────→ ←──────────────--- 32 bytes --──────────────→ ←──────────────--- 32 bytes ---──────────────→
    */

    struct TrimInfo {
        bool hasTrim; // 0x00
        uint256 trimRate; // 0x20
        address trimAddress; // 0x40
        uint256 expectAmountOut; // 0x60
        uint256 trimRate2; // 0x80
        address trimAddress2; // 0xa0
    }

    function _buildTrimInfoUnified(
        uint256 trimRate,
        address trimAddress,
        uint256 expectAmountOut,
        uint256 trimRate2,
        address trimAddress2
    ) internal pure returns (bytes memory) {
        // ensure trimRate and trimAddress are both set
        require(trimRate > 0 && trimAddress != address(0));
        // ensure trimRate2 and trimAddress2 are both set or both not set
        require(
            (trimRate2 == 0 && trimAddress2 == address(0)) ||
            (trimRate2 > 0 && trimAddress2 != address(0))
        );
        if (trimRate2 == 0) {
            return abi.encodePacked(
                bytes32(
                    (TRIM_FLAG & 0xffffffffffff0000000000000000000000000000000000000000000000000000) |
                    (uint256(expectAmountOut) & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
                ),
                bytes32(
                    (TRIM_FLAG & 0xffffffffffff0000000000000000000000000000000000000000000000000000) |
                    ((uint256(trimRate) << 160) &    0x000000000000ffffffffffff0000000000000000000000000000000000000000) |
                    (uint256(uint160(trimAddress)) & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
                )
            );
        } else {
            return abi.encodePacked(
                bytes32(
                    (TRIM_DUAL_FLAG & 0xffffffffffff0000000000000000000000000000000000000000000000000000) |
                    ((uint256(trimRate2) << 160) & 0x000000000000ffffffffffff0000000000000000000000000000000000000000) |
                    (uint256(uint160(trimAddress2)) & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
                ),
                bytes32(
                    (TRIM_DUAL_FLAG & 0xffffffffffff0000000000000000000000000000000000000000000000000000) |
                    (uint256(expectAmountOut) & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
                ),
                bytes32(
                    (TRIM_DUAL_FLAG & 0xffffffffffff0000000000000000000000000000000000000000000000000000) |
                    ((uint256(trimRate) << 160) & 0x000000000000ffffffffffff0000000000000000000000000000000000000000) |
                    (uint256(uint160(trimAddress)) & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
                )
            );
        }
    }

    function _parseTrimInfo(bytes memory trimInfo) internal pure returns (TrimInfo memory) {
        uint256 length = trimInfo.length;
        require(length == 64 || length == 96, "Invalid trim info length");
        TrimInfo memory info;
        bytes32 firstBytes;
        assembly {
            firstBytes := mload(add(trimInfo, length))
        }
        uint256 firstValue = uint256(firstBytes);
        uint256 flag = firstValue & 0xffffffffffff0000000000000000000000000000000000000000000000000000;
        info.hasTrim = ((flag == TRIM_FLAG || flag == TRIM_DUAL_FLAG));
        if (info.hasTrim) {
            info.trimRate = (firstValue >> 160) & 0xffffffffffff;
            info.trimAddress = address(uint160(firstValue & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff));
            bytes32 secondBytes;
            assembly {
                secondBytes := mload(sub(add(trimInfo, length), 32))
            }
            uint256 secondValue = uint256(secondBytes);
            info.expectAmountOut = secondValue & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
        }
        if (flag == TRIM_DUAL_FLAG) {
            bytes32 thirdBytes;
            assembly {
                thirdBytes := mload(sub(add(trimInfo, length), 64))
            }
            uint256 thirdValue = uint256(thirdBytes);
            info.trimRate2 = (thirdValue >> 160) & 0xffffffffffff;
            info.trimAddress2 = address(uint160(thirdValue & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff));
        }
        return info;
    }
}