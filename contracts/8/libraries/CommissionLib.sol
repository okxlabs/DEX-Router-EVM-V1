/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CommonUtils.sol";
import "../interfaces/AbstractCommissionLib.sol";
/// @title Base contract with common permit handling logics

abstract contract CommissionLib is AbstractCommissionLib, CommonUtils {
    uint256 internal constant _COMMISSION_RATE_MASK =
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
    uint256 internal constant _TO_B_COMMISSION_MASK =
        0x8000000000000000000000000000000000000000000000000000000000000000;

    uint256 internal constant _TRIM_FLAG_MASK =
        0xffffffffffff0000000000000000000000000000000000000000000000000000;
    uint256 internal constant _TRIM_EXPECT_AMOUNT_OUT_OR_ADDRESS_MASK =
        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant _TRIM_RATE_MASK =
        0x000000000000ffffffffffff0000000000000000000000000000000000000000;
    uint256 internal constant TRIM_FLAG =
        0x7777777711110000000000000000000000000000000000000000000000000000;
    uint256 internal constant TRIM_DUAL_FLAG =
        0x7777777722220000000000000000000000000000000000000000000000000000;

    event CommissionAndTrimInfo(
        uint256 commissionRate1,
        uint256 commissionRate2,
        bool isToBCommission,
        uint256 trimRate,
        uint256 chargeRate
    );

    // @notice CommissionFromTokenRecord is emitted in assembly, commentted out for contract size saving
    // event CommissionFromTokenRecord(
    //     address fromTokenAddress,
    //     uint256 commissionAmount,
    //     address referrerAddress
    // );

    // @notice CommissionToTokenRecord is emitted in assembly, commentted out for contract size saving
    // event CommissionToTokenRecord(
    //     address toTokenAddress,
    //     uint256 commissionAmount,
    //     address referrerAddress
    // );

    // @notice PositiveSlippageTrimRecord is emitted in assembly, commentted out for contract size saving
    // event PositiveSlippageTrimRecord(
    //     address toTokenAddress,
    //     uint256 trimAmount,
    //     address trimAddress
    // );

    // @notice PositiveSlippageChargeRecord is emitted in assembly, commentted out for contract size saving
    // event PositiveSlippageChargeRecord(
    //     address toTokenAddress,
    //     uint256 chargeAmount,
    //     address chargeAddress
    // );

    // set default value can change when need.
    uint256 internal constant commissionRateLimit = 30000000;
    uint256 internal constant DENOMINATOR = 10 ** 9;
    uint256 internal constant WAD = 1 ether;
    uint256 internal constant TRIM_RATE_LIMIT = 100;
    uint256 internal constant TRIM_DENOMINATOR = 1000;

    function _getCommissionAndTrimInfo()
        internal
        override
        returns (CommissionInfo memory commissionInfo, TrimInfo memory trimInfo)
    {
        assembly ("memory-safe") {
            // let freePtr := mload(0x40)
            // mstore(0x40, add(freePtr, 0x100))
            let commissionData := calldataload(sub(calldatasize(), 0x20))
            let flag := and(commissionData, _COMMISSION_FLAG_MASK)
            let isDualreferrers := or(
                eq(flag, FROM_TOKEN_COMMISSION_DUAL),
                eq(flag, TO_TOKEN_COMMISSION_DUAL)
            )
            mstore(
                commissionInfo,
                or(
                    eq(flag, FROM_TOKEN_COMMISSION),
                    eq(flag, FROM_TOKEN_COMMISSION_DUAL)
                )
            ) // isFromTokenCommission
            mstore(
                add(0x20, commissionInfo),
                or(
                    eq(flag, TO_TOKEN_COMMISSION),
                    eq(flag, TO_TOKEN_COMMISSION_DUAL)
                )
            ) // isToTokenCommission
            mstore(
                add(0x40, commissionInfo),
                shr(160, and(commissionData, _COMMISSION_RATE_MASK))
            ) //commissionRate1
            mstore(
                add(0x60, commissionInfo),
                and(commissionData, _ADDRESS_MASK)
            ) //referrerAddress1
            commissionData := calldataload(sub(calldatasize(), 0x40))
            mstore(
                add(0xe0, commissionInfo),
                gt(and(commissionData, _TO_B_COMMISSION_MASK), 0) //isToBCommission
            )
            mstore(
                add(0x80, commissionInfo),
                and(commissionData, _ADDRESS_MASK) //token
            )
            switch eq(isDualreferrers, 1)
            case 1 {
                let commissionData2 := calldataload(sub(calldatasize(), 0x60))
                mstore(
                    add(0xa0, commissionInfo),
                    shr(160, and(commissionData2, _COMMISSION_RATE_MASK))
                ) //commissionRate2
                mstore(
                    add(0xc0, commissionInfo),
                    and(commissionData2, _ADDRESS_MASK)
                ) //referrerAddress2
            }
            default {
                mstore(add(0xa0, commissionInfo), 0) //commissionRate2
                mstore(add(0xc0, commissionInfo), 0) //referrerAddress2
            }            
            // calculate offset based on commission flag
            let offset := 0x00
            if eq(isDualreferrers, 1) {
                offset := 0x60  // 96 bytes for dual commission
            }
            if or(
                eq(flag, FROM_TOKEN_COMMISSION),
                eq(flag, TO_TOKEN_COMMISSION)
            ) {
                offset := 0x40  // 64 bytes for single commission
            }
            // get first bytes32 of trim data
            let trimData := calldataload(sub(calldatasize(), add(offset, 32)))
            flag := and(trimData, _TRIM_FLAG_MASK)
            mstore(
                trimInfo,
                or(
                    eq(flag, TRIM_FLAG),
                    eq(flag, TRIM_DUAL_FLAG)
                )
            ) // hasTrim
            mstore(
                add(0x20, trimInfo),
                shr(160, and(trimData, _TRIM_RATE_MASK))
            ) // trimRate
            mstore(
                add(0x40, trimInfo),
                and(trimData, _TRIM_EXPECT_AMOUNT_OUT_OR_ADDRESS_MASK)
            ) // trimAddress
            // get second bytes32 of trim data
            trimData := calldataload(sub(calldatasize(), add(offset, 64)))
            mstore(
                add(0x60, trimInfo),
                and(trimData, _TRIM_EXPECT_AMOUNT_OUT_OR_ADDRESS_MASK)
            ) // expectAmountOut
            switch eq(flag, TRIM_DUAL_FLAG)
            case 1 {
                // get third bytes32 of trim data
                trimData := calldataload(sub(calldatasize(), add(offset, 96)))
                mstore(
                    add(0x80, trimInfo),
                    shr(160, and(trimData, _TRIM_RATE_MASK))
                ) // chargeRate
                mstore(
                    add(0xa0, trimInfo),
                    and(trimData, _TRIM_EXPECT_AMOUNT_OUT_OR_ADDRESS_MASK)
                ) // chargeAddress
            }
            default {
                mstore(add(0x80, trimInfo), 0) // chargeRate
                mstore(add(0xa0, trimInfo), 0) // chargeAddress
            }
        }

        if (commissionInfo.isFromTokenCommission || commissionInfo.isToTokenCommission || trimInfo.hasTrim) {
            emit CommissionAndTrimInfo(commissionInfo.commissionRate, commissionInfo.commissionRate2, commissionInfo.isToBCommission, trimInfo.trimRate, trimInfo.chargeRate);
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
                amount := balance(user)
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
        uint256 inputAmount,
        bool hasTrim,
        address toToken
    ) internal override returns (address middleReceiver, uint256 balanceBefore) {
        if (commissionInfo.isToTokenCommission || hasTrim) {
            middleReceiver = address(this);
            balanceBefore = _getBalanceOf(toToken, address(this));
        } else {
            middleReceiver = receiver;
        }

        if (commissionInfo.isFromTokenCommission) {
            _doCommissionFromTokenInternal(commissionInfo, payer, inputAmount);
        }
    }

    function _doCommissionFromTokenInternal(
        CommissionInfo memory commissionInfo,
        address payer,
        uint256 inputAmount
    ) private {
        assembly ("memory-safe") {
            // https://github.com/Vectorized/solady/blob/701406e8126cfed931645727b274df303fbcd94d/src/utils/FixedPointMathLib.sol#L595
            function _mulDiv(x, y, d) -> z {
                z := mul(x, y)
                // Equivalent to `require(d != 0 && (y == 0 || x <= type(uint256).max / y))`.
                if iszero(mul(or(iszero(x), eq(div(z, x), y)), d)) {
                    mstore(0x00, 0xad251c27) // `MulDivFailed()`.
                    revert(0x1c, 0x04)
                }
                z := div(z, d)
            }
            function _safeSub(x, y) -> z {
                if lt(x, y) {
                    mstore(0x00, 0x46e72d03) // `SafeSubFailed()`.
                    revert(0x1c, 0x04)
                }
                z := sub(x, y)
            }
            // a << 8 | b << 4 | c => 0xabc
            function _getStatus(token, isToB, hasNextRefer) -> d {
                let a := mul(eq(token, _ETH), 256)
                let b := mul(isToB, 16)
                let c := hasNextRefer
                d := add(a, add(b, c))
            }
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
            function _sendETH(to, amount) {
                let success := call(gas(), to, amount, 0, 0, 0, 0)
                if eq(success, 0) {
                    _revertWithReason(
                        0x0000001c20636f6d6d697373696f6e2077697468206574686572206572726f72, //commission with ether error
                        0x60
                    )
                }
            }
            function _claimToken(token, _payer, to, amount) {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x84))
                mstore(
                    freePtr,
                    0x0a5ea46600000000000000000000000000000000000000000000000000000000
                ) // claimTokens
                mstore(add(freePtr, 0x04), token)
                mstore(add(freePtr, 0x24), _payer)
                mstore(add(freePtr, 0x44), to)
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
            // get balance, then scale amount1, amount2 according to balance
            function _sendTokenWithinBalance(token, to1, rate1, to2, rate2)
                -> amount1Scaled, amount2Scaled
            {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x48))
                mstore(
                    freePtr,
                    0xa9059cbba9059cbb70a082310000000000000000000000000000000000000000
                ) // transfer transfer balanceOf
                // balanceOf
                mstore(add(freePtr, 0x0c), address())
                let success := staticcall(
                    gas(),
                    token,
                    add(freePtr, 0x08),
                    0x24,
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
                let rateTotal := add(rate1, rate2) // amount = 0.0000001
                amount1Scaled := _mulDiv(
                    _mulDiv(rate1, WAD, rateTotal),
                    balanceAfter,
                    WAD
                ) // WARNING: Precision issues may also exist!!
                if gt(amount1Scaled, balanceAfter) {
                    _revertWithReason(
                        0x00000015696e76616c696420616d6f756e74315363616c656400000000000000,
                        0x59
                    ) //invalid amount1Scaled
                }
                mstore(add(freePtr, 0x08), to1)
                mstore(add(freePtr, 0x28), amount1Scaled)
                success := call(
                    gas(),
                    token,
                    0,
                    add(freePtr, 0x4),
                    0x44,
                    0,
                    0x20
                )
                // https://github.com/transmissions11/solmate/blob/e5e0ed64c75e74974151780884e59071d026d84e/src/utils/SafeTransferLib.sol#L54
                if and(
                    iszero(and(eq(mload(0), 1), gt(returndatasize(), 31))),
                    success
                ) {
                    success := iszero(
                        or(iszero(extcodesize(token)), returndatasize())
                    )
                }
                if eq(success, 0) {
                    _revertWithReason(
                        0x0000001b7472616e7366657220746f6b656e2072656665726572206661696c00,
                        0x5f
                    ) //transfer token referrer fail
                }

                if gt(to2, 0) {
                    amount2Scaled := _safeSub(balanceAfter, amount1Scaled)

                    mstore(add(freePtr, 0x04), to2)
                    mstore(add(freePtr, 0x24), amount2Scaled)
                    success := call(gas(), token, 0, freePtr, 0x44, 0, 0x20)
                    // https://github.com/transmissions11/solmate/blob/e5e0ed64c75e74974151780884e59071d026d84e/src/utils/SafeTransferLib.sol#L54
                    if and(
                        iszero(and(eq(mload(0), 1), gt(returndatasize(), 31))),
                        success
                    ) {
                        success := iszero(
                            or(iszero(extcodesize(token)), returndatasize())
                        )
                    }
                    if eq(success, 0) {
                        _revertWithReason(
                            0x0000001b7472616e7366657220746f6b656e2072656665726572206661696c00,
                            0x5f
                        ) //transfer token referrer fail
                    }
                }
            }
            function _emitCommissionFromToken(token, amount, referrer) {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x60))
                mstore(freePtr, token)
                mstore(add(freePtr, 0x20), amount)
                mstore(add(freePtr, 0x40), referrer)
                log1(
                    freePtr,
                    0x60,
                    0x0d3b1268ca3dbb6d3d8a0ea35f44f8f9d58cf578d732680b71b6904fb2733e0d
                ) //emit CommissionFromTokenRecord(address,uint256,address)
            }

            let token, status
            {
                token := mload(add(commissionInfo, 0x80))
                let isToB := mload(add(commissionInfo, 0xe0))
                let hasNextRefer := gt(mload(add(commissionInfo, 0xa0)), 0)
                status := _getStatus(token, isToB, hasNextRefer)
            }
            
            let referrer1, referrer2, amount1, amount2, rate1, rate2
            rate1 := mload(add(commissionInfo, 0x40))
            rate2 := mload(add(commissionInfo, 0xa0))
            {
                // let totalRate := add(rate, rate2)
                if gt(add(rate1, rate2), commissionRateLimit) {
                    _revertWithReason(
                        0x0000001b6572726f7220636f6d6d697373696f6e2072617465206c696d697400,
                        0x5f
                    ) //"error commission rate limit"
                }
                referrer1 := mload(add(commissionInfo, 0x60))
                amount1 := div(
                    mul(inputAmount, rate1),
                    sub(DENOMINATOR, add(rate1, rate2))
                )
                referrer2 := mload(add(commissionInfo, 0xc0))
                amount2 := div(
                    mul(inputAmount, rate2),
                    sub(DENOMINATOR, add(rate1, rate2))
                )
            }

            switch status
            case 0x100 {
                _sendETH(referrer1, amount1)
                _emitCommissionFromToken(_ETH, amount1, referrer1)
            }
            case 0x101 {
                _sendETH(referrer1, amount1)
                _emitCommissionFromToken(_ETH, amount1, referrer1)
                _sendETH(referrer2, amount2)
                _emitCommissionFromToken(_ETH, amount2, referrer2)
            }
            case 0x110 {
                _sendETH(referrer1, amount1)
                _emitCommissionFromToken(_ETH, amount1, referrer1)
            }
            case 0x111 {
                _sendETH(referrer1, amount1)
                _emitCommissionFromToken(_ETH, amount1, referrer1)
                _sendETH(referrer2, amount2)
                _emitCommissionFromToken(_ETH, amount2, referrer2)
            }
            case 0x000 {
                _claimToken(token, payer, referrer1, amount1)
                _emitCommissionFromToken(token, amount1, referrer1)
            }
            case 0x001 {
                _claimToken(token, payer, referrer1, amount1)
                _emitCommissionFromToken(token, amount1, referrer1)
                _claimToken(token, payer, referrer2, amount2)
                _emitCommissionFromToken(token, amount2, referrer2)
            }
            case 0x010 {
                _claimToken(token, payer, address(), amount1)
                // considering the tax token, we first transfer it into dexrouter, then check balance, after that
                // scaled amount accordingly
                let amount1Scaled, amount2Scaled := _sendTokenWithinBalance(
                    token,
                    referrer1,
                    rate1,
                    0,
                    0
                )
                _emitCommissionFromToken(token, amount1Scaled, referrer1)
            }
            case 0x011 {
                _claimToken(token, payer, address(), add(amount1, amount2))
                // considering the tax token, we first transfer it into dexrouter, then check balance, after that
                // scaled amount accordingly
                let amount1Scaled, amount2Scaled := _sendTokenWithinBalance(
                    token,
                    referrer1,
                    rate1,
                    referrer2,
                    rate2
                )
                _emitCommissionFromToken(token, amount1Scaled, referrer1)
                _emitCommissionFromToken(token, amount2Scaled, referrer2)
            }
            default {
                _revertWithReason(
                    0x0000000e696e76616c6964207374617475730000000000000000000000000000,
                    0x52
                ) // invalid status
            }
        }
    }

    function _doCommissionAndTrimToToken(
        CommissionInfo memory commissionInfo,
        address receiver,
        uint256 balanceBefore,
        address toToken,
        TrimInfo memory trimInfo
    ) internal override returns (uint256 totalAmount) {
        if (!commissionInfo.isToTokenCommission && !trimInfo.hasTrim) {
            return 0;
        }
        uint256 balanceAfter = _getBalanceOf(toToken, address(this));
        require(balanceAfter >= balanceBefore, "invalid balance after");
        uint256 inputAmount = balanceAfter - balanceBefore;

        // process commission
        if (commissionInfo.isToTokenCommission) {
            require(commissionInfo.commissionRate + commissionInfo.commissionRate2 <= commissionRateLimit, "error commission rate limit");
            uint256 commissionAmount = inputAmount * (commissionInfo.commissionRate + commissionInfo.commissionRate2) / DENOMINATOR;
            _doCommissionOrTrimToTokenInternal(
                true,
                toToken,
                commissionAmount,
                commissionInfo.commissionRate,
                commissionInfo.refererAddress,
                commissionInfo.commissionRate2,
                commissionInfo.refererAddress2
            );
            totalAmount = commissionAmount;
            inputAmount -= commissionAmount;
        }

        // process trim
        if (trimInfo.hasTrim && inputAmount > trimInfo.expectAmountOut) {
            require(trimInfo.trimRate <= TRIM_RATE_LIMIT, "error trim rate limit");
            require(trimInfo.chargeRate <= TRIM_DENOMINATOR, "error charge rate");
            uint256 trimAmount = inputAmount - trimInfo.expectAmountOut;
            uint256 allowedMaxTrimAmount = inputAmount * trimInfo.trimRate / TRIM_DENOMINATOR;
            if (trimAmount > allowedMaxTrimAmount) {
                trimAmount = allowedMaxTrimAmount;
            }
            _doCommissionOrTrimToTokenInternal(
                false,
                toToken,
                trimAmount,
                (TRIM_DENOMINATOR - trimInfo.chargeRate),
                trimInfo.trimAddress,
                trimInfo.chargeRate,
                trimInfo.chargeAddress
            );
            totalAmount += trimAmount;
            inputAmount -= trimAmount;
        }

        // transfer toToken to receiver
        _sendETHOrToken(toToken, receiver, inputAmount);
    }

    // Process commission or trim to token
    function _doCommissionOrTrimToTokenInternal(
        bool isCommission,
        address toToken,
        uint256 totalAmount,
        uint256 rate1,
        address address1,
        uint256 rate2,
        address address2
    ) private {
        assembly ("memory-safe") {
            // a << 4 | b => 0xab
            function _getStatus(flag, token) -> c {
                let a := mul(gt(flag, 0), 16)
                let b := eq(token, _ETH)
                c := add(a, b)
            }
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
            function _sendETH(to, amount) {
                let success := call(gas(), to, amount, 0, 0, 0, 0)
                if eq(success, 0) {
                    _revertWithReason(
                        0x0000001173656e64206574686572206661696c65640000000000000000000000,
                        0x55
                    ) // "send ether failed"
                }
            }
            function _sendToken(token, to, amount) {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x44))
                mstore(
                    freePtr,
                    0xa9059cbb00000000000000000000000000000000000000000000000000000000
                ) // transfer
                mstore(add(freePtr, 0x04), to)
                mstore(add(freePtr, 0x24), amount)
                let success := call(
                    gas(),
                    token,
                    0,
                    freePtr,
                    0x44,
                    0,
                    0x20
                )
                if and(
                    iszero(and(eq(mload(0), 1), gt(returndatasize(), 31))),
                    success
                ) {
                    success := iszero(
                        or(iszero(extcodesize(token)), returndatasize())
                    )
                }
                if eq(success, 0) {
                    _revertWithReason(
                        0x000000157472616e7366657220746f6b656e206661696c656400000000000000,
                        0x59
                    ) // "transfer token failed"
                }
            }
            function _emitCommissionToToken(token, amount, referrer) {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x60))
                mstore(freePtr, token)
                mstore(add(freePtr, 0x20), amount)
                mstore(add(freePtr, 0x40), referrer)
                log1(
                    freePtr,
                    0x60,
                    0xf171268de859ec269c52bbfac94dcb7715e784de194342abb284bf34fd30b32d
                ) //emit CommissionToTokenRecord(address,uint256,address)
            }
            function _emitPositiveSlippageTrimRecord(token, trimAmount, trimAddress) {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x60))
                mstore(freePtr, token)
                mstore(add(freePtr, 0x20), trimAmount)
                mstore(add(freePtr, 0x40), trimAddress)
                log1(
                    freePtr,
                    0x60,
                    0x7bec7d55a62a7a7b8068f1533e2a3bbf727b3e2e57f30c576fe159da60e09a65
                ) // emit PositiveSlippageTrimRecord(address,uint256,address)
            }
            function _emitPositiveSlippageChargeRecord(token, chargeAmount, chargeAddress) {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x60))
                mstore(freePtr, token)
                mstore(add(freePtr, 0x20), chargeAmount)
                mstore(add(freePtr, 0x40), chargeAddress)
                log1(
                    freePtr,
                    0x60,
                    0xfd08115c8e43d2a49d95ee18d7f69b8bbac60bd368c73cf22d30664a22a0626d
                ) // emit PositiveSlippageChargeRecord(address,uint256,address)
            }

            let amount1 := div(mul(totalAmount, rate1), add(rate1, rate2))
            let amount2 := sub(totalAmount, amount1)
            address1 := shr(96, shl(96, address1))
            address2 := shr(96, shl(96, address2))

            let status := _getStatus(isCommission, toToken)
            switch status
            case 0x11 { // commission with ETH
                if gt(rate1, 0) {
                    _sendETH(address1, amount1)
                    _emitCommissionToToken(_ETH, amount1, address1)
                }
                if gt(rate2, 0) {
                    _sendETH(address2, amount2)
                    _emitCommissionToToken(_ETH, amount2, address2)
                }
            }
            case 0x10 { // commission with token
                if gt(rate1, 0) {
                    _sendToken(toToken, address1, amount1)
                    _emitCommissionToToken(toToken, amount1, address1)
                }
                if gt(rate2, 0) {
                    _sendToken(toToken, address2, amount2)
                    _emitCommissionToToken(toToken, amount2, address2)
                }
            }
            case 0x01 { // trim with ETH
                if gt(rate1, 0) {
                    _sendETH(address1, amount1)
                    _emitPositiveSlippageTrimRecord(_ETH, amount1, address1)
                }
                if gt(rate2, 0) {
                    _sendETH(address2, amount2)
                    _emitPositiveSlippageChargeRecord(_ETH, amount2, address2)
                }
            }
            case 0x00 { // trim with token
                if gt(rate1, 0) {
                    _sendToken(toToken, address1, amount1)
                    _emitPositiveSlippageTrimRecord(toToken, amount1, address1)
                }
                if gt(rate2, 0) {
                    _sendToken(toToken, address2, amount2)
                    _emitPositiveSlippageChargeRecord(toToken, amount2, address2)
                }
            }
            default {
                _revertWithReason(
                    0x0000000e696e76616c6964207374617475730000000000000000000000000000,
                    0x52
                ) // invalid status
            }
        }
    }

    function _sendETHOrToken(
        address token,
        address to,
        uint256 amount
    ) private {
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
            function _sendETH(_to, _amount) {
                let success := call(gas(), _to, _amount, 0, 0, 0, 0)
                if eq(success, 0) {
                    _revertWithReason(
                        0x0000001173656e64206574686572206661696c65640000000000000000000000,
                        0x55
                    ) // "send ether failed"
                }
            }
            function _sendToken(_token, _to, _amount) {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x44))
                mstore(
                    freePtr,
                    0xa9059cbb00000000000000000000000000000000000000000000000000000000
                ) // transfer
                mstore(add(freePtr, 0x04), _to)
                mstore(add(freePtr, 0x24), _amount)
                let success := call(
                    gas(),
                    _token,
                    0,
                    freePtr,
                    0x44,
                    0,
                    0x20
                )
                if and(
                    iszero(and(eq(mload(0), 1), gt(returndatasize(), 31))),
                    success
                ) {
                    success := iszero(
                        or(iszero(extcodesize(_token)), returndatasize())
                    )
                }
                if eq(success, 0) {
                    _revertWithReason(
                        0x000000157472616e7366657220746f6b656e206661696c656400000000000000,
                        0x59
                    ) // "transfer token failed"
                }
            }
            switch eq(token, _ETH)
            case 1 {
                _sendETH(shr(96, shl(96, to)), amount)
            }
            default {
                _sendToken(token, shr(96, shl(96, to)), amount)
            }
        }
    }

    function _validateCommissionInfo(
        CommissionInfo memory commissionInfo,
        address fromToken,
        address toToken,
        uint256 mode
    ) internal pure override {
        if ((
            (mode & _MODE_NO_TRANSFER) != 0 
         || (mode & _MODE_BY_INVEST) != 0
         || (mode & _MODE_PERMIT2) != 0
        )
         && commissionInfo.isFromTokenCommission) {
            revert("From token commission not supported");
        }
        if(fromToken == toToken) {
            revert("Invalid tokens");
        }
        if (commissionInfo.isFromTokenCommission && commissionInfo.isToTokenCommission) {
            revert("Invalid commission direction");
        }
        
        require(
            (commissionInfo.isFromTokenCommission && commissionInfo.token == fromToken)
                || (commissionInfo.isToTokenCommission && commissionInfo.token == toToken)
                || (!commissionInfo.isFromTokenCommission && !commissionInfo.isToTokenCommission),
            "Invalid commission info"
        );
    }
}