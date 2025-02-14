/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CommonUtils.sol";
/// @title Base contract with common permit handling logics

abstract contract CommissionLib is CommonUtils {
    uint256 internal constant _COMMISSION_FEE_MASK =
        0x000000000000ffffffffffff0000000000000000000000000000000000000000;
    uint256 internal constant _COMMISSION_FLAG_MASK =
        0xffffffffffff0000000000000000000000000000000000000000000000000000;
    uint256 internal constant FROM_TOKEN_COMMISSION =
        0x3ca20afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 internal constant TO_TOKEN_COMMISSION =
        0x3ca20afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 internal constant FROM_TOKEN_COMMISSION_DUAL =
        0x22220afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 internal constant TO_TOKEN_COMMISSION_DUAL =
        0x22220afc2bbb0000000000000000000000000000000000000000000000000000;

    event CommissionRecord(uint256 commissionAmount, address referrerAddress);

    // set default vaule. can change when need.
    uint256 public constant commissionRateLimit = 300;

    struct CommissionInfo {
        bool isFromTokenCommission;
        bool isToTokenCommission;
        uint256 commissionRate;
        address refererAddress;
        address token;
        uint256 commissionRate2;
        address refererAddress2;
    }

    function _getCommissionInfo()
        internal
        pure
        returns (CommissionInfo memory commissionInfo)
    {
        assembly ("memory-safe") {
            let freePtr := mload(0x40)
            mstore(0x40, add(freePtr, 0xe0))
            let commissionData := calldataload(sub(calldatasize(), 0x20))
            let flag := and(commissionData, _COMMISSION_FLAG_MASK)
            let isDualReferrers := or(
                eq(flag, FROM_TOKEN_COMMISSION_DUAL),
                eq(flag, TO_TOKEN_COMMISSION_DUAL)
            )
            mstore(
                commissionInfo,
                or(eq(flag, FROM_TOKEN_COMMISSION), eq(flag, FROM_TOKEN_COMMISSION_DUAL))
            ) // isFromTokenCommission
            mstore(
                add(0x20, commissionInfo),
                or(eq(flag, TO_TOKEN_COMMISSION), eq(flag, TO_TOKEN_COMMISSION_DUAL))
            )
            mstore(
                add(0x40, commissionInfo),
                shr(160, and(commissionData, _COMMISSION_FEE_MASK))
            )
            mstore(
                add(0x60, commissionInfo),
                and(commissionData, _ADDRESS_MASK)
            )
            mstore(
                add(0x80, commissionInfo),
                and(calldataload(sub(calldatasize(), 0x40)), _ADDRESS_MASK)
            )
            switch eq(isDualReferrers, 1)
            case 1 {
                let commissionData2 := calldataload(sub(calldatasize(), 0x60))
                mstore(
                    add(0xa0, commissionInfo),
                    shr(160, and(commissionData2, _COMMISSION_FEE_MASK))
                ) //commissionRate2
                mstore(
                    add(0xc0, commissionInfo),
                    and(commissionData2, _ADDRESS_MASK)
                ) //refererAddress2
            }
            default {
                mstore(
                    add(0xa0, commissionInfo), 
                    0
                ) //commissionRate2
                mstore(
                    add(0xc0, commissionInfo), 
                    0
                ) //refererAddress2
            }
        }
    }

    function _getBalanceOf(
        address token,
        address user
    ) internal returns (uint256 amount) {
        assembly {
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
            switch eq(token, _ETH)
            case 1 {
                amount := selfbalance()
            }
            default {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x24))
                mstore(
                    freePtr,
                    0x70a0823100000000000000000000000000000000000000000000000000000000
                ) //balanceOf
                mstore(add(freePtr, 0x04), user)
                let success := staticcall(gas(), token, freePtr, 0x24, 0, 0x20)
                if eq(success, 0) {
                    _revertWithReason(
                        0x000000146765742062616c616e63654f66206661696c65640000000000000000,
                        0x58
                    )
                }
                amount := mload(0x00)
            }
        }
    }

    function _doCommissionFromToken(
        CommissionInfo memory commissionInfo,
        address payer,
        address receiver,
        uint256 inputAmount
    ) internal returns (address, uint256) {
        if (commissionInfo.isToTokenCommission) {
            return (
                address(this),
                _getBalanceOf(commissionInfo.token, address(this))
            );
        }
        if (!commissionInfo.isFromTokenCommission || commissionInfo.commissionRate == 0) {
            return (receiver, 0);
        }
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
            let rate := mload(add(commissionInfo, 0x40))
            let rate2 := mload(add(commissionInfo, 0xa0))
            let totalRate := add(rate, rate2)
            if gt(totalRate, commissionRateLimit) {
                _revertWithReason(
                    0x0000001b6572726f7220636f6d6d697373696f6e2072617465206c696d697400,
                    0x5f
                ) //"error commission rate limit"
            }
            let token := mload(add(commissionInfo, 0x80))
            let referer := mload(add(commissionInfo, 0x60))
            let amount := div(mul(inputAmount, rate), sub(10000, totalRate))
            switch eq(token, _ETH)
            case 1 {
                let success := call(gas(), referer, amount, 0, 0, 0, 0)
                if eq(success, 0) {
                    _revertWithReason(
                        0x0000001b636f6d6d697373696f6e2077697468206574686572206572726f7200,
                        0x5f
                    )
                }
            }
            default {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x84))
                mstore(
                    freePtr,
                    0x0a5ea46600000000000000000000000000000000000000000000000000000000
                ) // claimTokens
                mstore(add(freePtr, 0x04), token)
                mstore(add(freePtr, 0x24), payer)
                mstore(add(freePtr, 0x44), referer)
                mstore(add(freePtr, 0x64), amount)
                let success := call(
                    gas(),
                    _APPROVE_PROXY,
                    0,
                    freePtr,
                    0x84,
                    0,
                    0
                )
                if eq(success, 0) {
                    _revertWithReason(
                        0x00000013636c61696d20746f6b656e73206661696c6564000000000000000000,
                        0x57
                    )
                }
            }
            let freePtr := mload(0x40)
            mstore(0x40, add(freePtr, 0x40))
            mstore(freePtr, amount)
            mstore(add(freePtr, 0x20), referer)
            log1(
                freePtr,
                0x40,
                0xffc60ee157a42f4d8edbd1897e6581a96d9ed04e44fb2ab53a47ce1eb8f2775b
            ) //emit CommissionRecord(commissionAmount, refererAddress);
            if gt(rate2, 0) {
                let referer2 := mload(add(commissionInfo, 0xc0))
                let amount2 := div(mul(inputAmount, rate2), sub(10000, totalRate))

                switch eq(token, _ETH)
                case 1 {
                    let success := call(gas(), referer2, amount2, 0, 0, 0, 0)
                    if eq(success, 0) {
                        _revertWithReason(
                            0x0000001b636f6d6d697373696f6e2077697468206574686572206572726f7200,
                            0x5f
                        )
                    }
                }
                default {
                    let freePtr2 := mload(0x40)
                    mstore(0x40, add(freePtr2, 0x84))
                    mstore(
                        freePtr2,
                        0x0a5ea46600000000000000000000000000000000000000000000000000000000
                    )
                    mstore(add(freePtr2, 0x04), token)
                    mstore(add(freePtr2, 0x24), payer)
                    mstore(add(freePtr2, 0x44), referer2)
                    mstore(add(freePtr2, 0x64), amount2)
                    let success := call(
                        gas(), 
                        _APPROVE_PROXY, 
                        0, 
                        freePtr2, 
                        0x84, 
                        0, 
                        0
                    )
                    if eq(success, 0) {
                        _revertWithReason(
                            0x00000013636c61696d20746f6b656e73206661696c6564000000000000000000,
                            0x57
                        )
                    }
                }
                // Emit event for second commission
                let freePtr2 := mload(0x40)
                mstore(0x40, add(freePtr2, 0x40))
                mstore(freePtr2, amount2)
                mstore(add(freePtr2, 0x20), referer2)
                log1(
                    freePtr2,
                    0x40,
                    0xffc60ee157a42f4d8edbd1897e6581a96d9ed04e44fb2ab53a47ce1eb8f2775b
                )
            }
        }
        return (receiver, 0);
    }

    function _doCommissionToToken(
        CommissionInfo memory commissionInfo,
        address receiver,
        uint256 balanceBefore
    ) internal returns (uint256 amount) {
        if (!commissionInfo.isToTokenCommission || commissionInfo.commissionRate == 0) {
            return 0;
        }
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
            let rate := mload(add(commissionInfo, 0x40))
            let rate2 := mload(add(commissionInfo, 0xa0))
            let totalRate := add(rate, rate2)
            if gt(totalRate, commissionRateLimit) {
                _revertWithReason(
                    0x0000001b6572726f7220636f6d6d697373696f6e2072617465206c696d697400,
                    0x5f
                ) //"error commission rate limit"
            }
            let token := mload(add(commissionInfo, 0x80))
            let referer := mload(add(commissionInfo, 0x60))
            let eventPtr := mload(0x40)
            mstore(0x40, add(eventPtr, 0x40))

            switch eq(token, _ETH)
            case 1 {
                if lt(selfbalance(), balanceBefore) {
                    _revertWithReason(
                        0x0000000a737562206661696c65640000000000000000000000000000000000000,
                        0x4d
                    ) // sub failed
                }
                let inputAmount := sub(selfbalance(), balanceBefore)
                amount := div(mul(inputAmount, rate), 10000)
                let success := call(gas(), referer, amount, 0, 0, 0, 0)
                if eq(success, 0) {
                    _revertWithReason(
                        0x000000197472616e73666572206574682072656665726572206661696c000000,
                        0x5d
                    ) // transfer eth referer fail
                }
                mstore(eventPtr, amount)
                mstore(add(eventPtr, 0x20), referer)
                log1(
                    eventPtr,
                    0x40,
                    0xffc60ee157a42f4d8edbd1897e6581a96d9ed04e44fb2ab53a47ce1eb8f2775b
                ) //emit CommissionRecord(commissionAmount1, refererAddress1);
                if gt(rate2, 0){
                    let referer2 := mload(add(commissionInfo, 0xc0))
                    let amount2 := div(mul(inputAmount, rate2), 10000)
                    amount := add(amount, amount2)
                    let success2 := call(gas(), referer2, amount2, 0, 0, 0, 0)
                    if eq(success2, 0) {
                        _revertWithReason(
                            0x000000197472616e73666572206574682072656665726572206661696c000000,
                            0x5d
                        ) // transfer eth referer fail
                    }
                    mstore(eventPtr, amount2)
                    mstore(add(eventPtr, 0x20), referer2)
                    log1(
                        eventPtr,
                        0x40,
                        0xffc60ee157a42f4d8edbd1897e6581a96d9ed04e44fb2ab53a47ce1eb8f2775b
                    ) //emit CommissionRecord(commissionAmount2, refererAddress2);
                }
                success := call(
                    gas(),
                    receiver,
                    sub(inputAmount, amount),
                    0,
                    0,
                    0,
                    0
                )
                if eq(success, 0) {
                    _revertWithReason(
                        0x0000001a7472616e7366657220657468207265636569766572206661696c0000,
                        0x5e
                    ) // transfer eth receiver fail
                }
            }
            default {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x4c))
                mstore(
                    freePtr,
                    0xa9059cbba9059cbba9059cbb70a0823100000000000000000000000000000000
                ) // transfer transfer transfer balanceOf
                mstore(add(freePtr, 0x10), address())
                let success := staticcall(
                    gas(),
                    token,
                    add(freePtr, 12),
                    36,
                    0,
                    0x20
                )
                if eq(success, 0) {
                    _revertWithReason(
                        0x000000146765742062616c616e63654f66206661696c65640000000000000000,
                        0x58
                    )
                }
                let balanceAfter := mload(0x00)
                if lt(balanceAfter, balanceBefore) {
                    _revertWithReason(
                        0x0000000a737562206661696c65640000000000000000000000000000000000000,
                        0x4d
                    ) // sub failed
                }
                let inputAmount := sub(balanceAfter, balanceBefore)
                amount := div(mul(inputAmount, rate), 10000)
                mstore(add(freePtr, 0x0c), referer)
                mstore(add(freePtr, 0x2c), amount)
                success := call(gas(), token, 0, add(freePtr, 8), 0x44, 0, 0)
                if eq(success, 0) {
                    _revertWithReason(
                        0x0000001b7472616e7366657220746f6b656e2072656665726572206661696c00,
                        0x5f
                    ) //transfer token referer fail
                }
                mstore(eventPtr, amount)
                mstore(add(eventPtr, 0x20), referer)
                log1(
                    eventPtr,
                    0x40,
                    0xffc60ee157a42f4d8edbd1897e6581a96d9ed04e44fb2ab53a47ce1eb8f2775b
                ) //emit CommissionRecord(commissionAmount1, refererAddress1);
                if gt(rate2, 0){
                    let referer2 := mload(add(commissionInfo, 0xc0))
                    let amount2 := div(mul(inputAmount, rate2), 10000)
                    amount := add(amount, amount2)
                    mstore(add(freePtr, 0x08), referer2)
                    mstore(add(freePtr, 0x28), amount2)
                    success := call(gas(), token, 0, add(freePtr, 4), 0x44, 0, 0)
                    if eq(success, 0) {
                        _revertWithReason(
                            0x0000001b7472616e7366657220746f6b656e2072656665726572206661696c00,
                            0x5f
                        ) //transfer token referer fail
                    }
                    mstore(eventPtr, amount2)
                    mstore(add(eventPtr, 0x20), referer2)
                    log1(
                        eventPtr,
                        0x40,
                        0xffc60ee157a42f4d8edbd1897e6581a96d9ed04e44fb2ab53a47ce1eb8f2775b
                    ) //emit CommissionRecord(commissionAmount2, refererAddress2);
                }
                mstore(add(freePtr, 0x04), receiver)
                mstore(add(freePtr, 0x24), sub(inputAmount, amount))
                success := call(gas(), token, 0, freePtr, 0x44, 0, 0)
                if eq(success, 0) {
                    _revertWithReason(
                        0x0000001c7472616e7366657220746f6b656e207265636569766572206661696c,
                        0x60
                    ) //transfer token receiver fail
                }
            }
        }
    }
}
