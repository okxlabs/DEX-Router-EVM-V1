// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommissionHelper {
    uint256 internal constant FROM_TOKEN_COMMISSION =
        0x3ca20afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 internal constant TO_TOKEN_COMMISSION =
        0x3ca20afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 internal constant FROM_TOKEN_COMMISSION_DUAL =
        0x22220afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 internal constant TO_TOKEN_COMMISSION_DUAL =
        0x22220afc2bbb0000000000000000000000000000000000000000000000000000;

    // Parse commission info from encoded bytes
    // Returns a struct containing all parsed commission parameters
    struct CommissionInfo {
        bool isFromTokenCommission;
        bool isToTokenCommission;
        address token;
        uint256 commissionRate;
        address refererAddress;
        uint256 commissionRate2;
        address refererAddress2;
        bool isToBCommission;
        bool isDualCommission;
    }

   // Unified commission info builder for both single and dual commission
    // isFromTokenCommission和isToTokenCommission 不能同时为true和false
    // commissionRate和refererAddress必须同时有值
    // commissionRate2和refererAddress2必须同时有值
    function _buildCommissionInfoUnified(
        bool isFromTokenCommission,
        bool isToTokenCommission,
        address token,
        uint256 commissionRate,
        address refererAddr,
        uint256 commissionRate2,
        address refererAddr2,
        bool isToBCommission
    ) internal pure returns (bytes memory) {
        // 校验 isFromTokenCommission 和 isToTokenCommission 不能同时为true或同时为false
        require(
            isFromTokenCommission != isToTokenCommission,
            "Exactly one of isFromTokenCommission or isToTokenCommission must be true"
        );
        // 校验 commissionRate 和 refererAddress 必须同时有值
        require(
            (commissionRate == 0 && refererAddr == address(0)) ||
            (commissionRate > 0 && refererAddr != address(0)),
            "commissionRate and refererAddress must both be set or both be unset"
        );
        // 校验 commissionRate2 和 refererAddress2 必须同时有值
        require(
            (commissionRate2 == 0 && refererAddr2 == address(0)) ||
            (commissionRate2 > 0 && refererAddr2 != address(0)),
            "commissionRate2 and refererAddress2 must both be set or both be unset"
        );
        uint256 toBCommissionFlag = isToBCommission ? (1 << 255) : 0;
        if (refererAddr2 == address(0)) {
            // Single commission logic
            uint256 flagValue;
            if (isFromTokenCommission) {
                flagValue = FROM_TOKEN_COMMISSION;
            } else if (isToTokenCommission) {
                flagValue = TO_TOKEN_COMMISSION;
            } else {
                // unreachable, already checked
                return abi.encodePacked(token, bytes32(0));
            }
            return abi.encodePacked(
                bytes32(uint256(uint160(token)) | toBCommissionFlag),
                bytes32(
                    (flagValue & 0xffffffffffff0000000000000000000000000000000000000000000000000000) |
                    ((uint256(commissionRate) << 160) & 0x000000000000ffffffffffff0000000000000000000000000000000000000000) |
                    (uint256(uint160(refererAddr)) & 0x00000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
                )
            );
        } else {
            // Dual commission logic
            uint256 flagValue;
            if (isFromTokenCommission) {
                flagValue = FROM_TOKEN_COMMISSION_DUAL;
            } else if (isToTokenCommission) {
                flagValue = TO_TOKEN_COMMISSION_DUAL;
            } else {
                flagValue = FROM_TOKEN_COMMISSION_DUAL;
            }
            return abi.encodePacked(
                bytes32(
                    (flagValue & 0xffffffffffff0000000000000000000000000000000000000000000000000000) |
                    ((uint256(commissionRate2) << 160) & 0x000000000000ffffffffffff0000000000000000000000000000000000000000) |
                    (uint256(uint160(refererAddr2)) & 0x00000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
                ),
                bytes32(uint256(uint160(token)) | toBCommissionFlag),
                bytes32(
                    (flagValue & 0xffffffffffff0000000000000000000000000000000000000000000000000000) |
                    ((uint256(commissionRate) << 160) & 0x000000000000ffffffffffff0000000000000000000000000000000000000000) |
                    (uint256(uint160(refererAddr)) & 0x00000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
                )
            );
        }
    }

    function _parseCommissionInfo(bytes memory commissionInfo) internal pure returns (CommissionInfo memory) {
        require(commissionInfo.length >= 64, "Invalid commission info length");
        
        CommissionInfo memory info;
        
        // For dual commission, the structure is:
        // First 32 bytes: flag + commissionRate2 + refererAddress2
        // Second 32 bytes: token (with toB flag)
        // Third 32 bytes: flag + commissionRate + refererAddress
        
        // Parse the first 32 bytes to get flag and first commission info
        bytes32 firstBytes;
        assembly {
            firstBytes := mload(add(commissionInfo, 32))
        }
        uint256 firstValue = uint256(firstBytes);
        
        // Extract flag value (first 6 bytes)
        uint256 flagValue = (firstValue & 0xffffffffffff0000000000000000000000000000000000000000000000000000);
        
        // Parse the second 32 bytes to get token and toB flag
        bytes32 secondBytes;
        assembly {
            secondBytes := mload(add(commissionInfo, 64))
        }
        uint256 secondValue = uint256(secondBytes);
        
        // Extract token address (remove the toBCommission flag)
        info.token = address(uint160(secondValue & 0x00000000000000000000000000ffffffffffffffffffffffffffffffffffffffff));
        info.isToBCommission = (secondValue & (1 << 255)) != 0;
        
        // Determine commission type based on flag
        if (flagValue == FROM_TOKEN_COMMISSION) {
            info.isFromTokenCommission = true;
            info.isToTokenCommission = false;
            info.isDualCommission = false;
        } else if (flagValue == TO_TOKEN_COMMISSION) {
            info.isFromTokenCommission = false;
            info.isToTokenCommission = true;
            info.isDualCommission = false;
        } else if (flagValue == FROM_TOKEN_COMMISSION_DUAL) {
            info.isFromTokenCommission = true;
            info.isToTokenCommission = false;
            info.isDualCommission = true;
        } else if (flagValue == TO_TOKEN_COMMISSION_DUAL) {
            info.isFromTokenCommission = false;
            info.isToTokenCommission = true;
            info.isDualCommission = true;
        } else {
            // No commission
            info.isFromTokenCommission = false;
            info.isToTokenCommission = false;
            info.isDualCommission = false;
        }
        
        if (info.isDualCommission) {
            // Dual commission: parse both sets of parameters
            require(commissionInfo.length >= 96, "Invalid dual commission info length");
            
            // Extract first commission parameters from first bytes
            info.commissionRate2 = (firstValue >> 160) & 0xffffffffffff;
            info.refererAddress2 = address(uint160(firstValue & 0x00000000000000000000000000ffffffffffffffffffffffffffffffffffffffff));
            
            // Parse third 32 bytes for second commission parameters
            bytes32 thirdBytes;
            assembly {
                thirdBytes := mload(add(commissionInfo, 96))
            }
            uint256 thirdValue = uint256(thirdBytes);
            
            info.commissionRate = (thirdValue >> 160) & 0xffffffffffff;
            info.refererAddress = address(uint160(thirdValue & 0x00000000000000000000000000ffffffffffffffffffffffffffffffffffffffff));
        } else {
            // Single commission: parse parameters from first bytes
            info.commissionRate = (firstValue >> 160) & 0xffffffffffff;
            info.refererAddress = address(uint160(firstValue & 0x00000000000000000000000000ffffffffffffffffffffffffffffffffffffffff));
            
            // Set dual commission parameters to zero
            info.commissionRate2 = 0;
            info.refererAddress2 = address(0);
        }
        
        return info;
    }
}