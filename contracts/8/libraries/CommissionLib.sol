/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base contract with common permit handling logics
abstract contract CommissionLib {
    uint256 internal constant _REFERRER_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant _COMMISSION_FEE_MASK = 0x000000000000ffffffffffff0000000000000000000000000000000000000000;
    uint256 internal constant _COMMISSION_FLAG_MASK = 0xffffffffffff0000000000000000000000000000000000000000000000000000;
    uint256 internal constant OKX_COMMISSION = 0x3ca20afc2aaa0000000000000000000000000000000000000000000000000000;

    event CommissionRecord(uint256 commitssonAmount, address referrerAddress);
    
    // set default vaule. can change when need.
    uint256 public constant commissionRateLimit = 300;
}
