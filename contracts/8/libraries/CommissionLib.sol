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
    uint256 internal constant FROM_TOKEN_COMMISSION_MULTIPLE =
        0x88880afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 internal constant TO_TOKEN_COMMISSION_MULTIPLE =
        0x88880afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 internal constant _COMMISSION_LENGTH_MASK =
        0x00ff000000000000000000000000000000000000000000000000000000000000;
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

            let commissionData := calldataload(sub(calldatasize(), 0x20))
            let flag := and(commissionData, _COMMISSION_FLAG_MASK)
            let referrerNum := 0
            if or(
                eq(flag, FROM_TOKEN_COMMISSION),
                eq(flag, TO_TOKEN_COMMISSION)
            ) {
                referrerNum := 1
            }
            if or(
                eq(flag, FROM_TOKEN_COMMISSION_DUAL),
                eq(flag, TO_TOKEN_COMMISSION_DUAL)
            ) {
                referrerNum := 2
            }
            if or(
                eq(flag, FROM_TOKEN_COMMISSION_MULTIPLE),
                eq(flag, TO_TOKEN_COMMISSION_MULTIPLE)
            ) {
                referrerNum := 3 // default referrer num to load real encoded referrer num
            }
            mstore(
                commissionInfo,
                or(
                    or(
                        eq(flag, FROM_TOKEN_COMMISSION),
                        eq(flag, FROM_TOKEN_COMMISSION_DUAL)
                    ),
                    eq(flag, FROM_TOKEN_COMMISSION_MULTIPLE)
                )
            ) // isFromTokenCommission
            mstore(
                add(0x20, commissionInfo),
                or(
                    or(
                        eq(flag, TO_TOKEN_COMMISSION),
                        eq(flag, TO_TOKEN_COMMISSION_DUAL)
                    ),
                    eq(flag, TO_TOKEN_COMMISSION_MULTIPLE)
                )
            ) // isToTokenCommission
            switch gt(referrerNum, 0)
            case 1 {
                mstore(
                    add(0xa0, commissionInfo),
                    shr(160, and(commissionData, _COMMISSION_RATE_MASK))
                ) // 1st commissionRate
                mstore(
                    add(0xc0, commissionInfo),
                    and(commissionData, _ADDRESS_MASK)
                ) // 1st referrerAddress
                commissionData := calldataload(sub(calldatasize(), 0x40))
                let toBCommission := NO_TO_B_MODE // default toBCommission is 1 for no-toB commission when commissionData exists
                if gt(and(commissionData, _TO_B_COMMISSION_MASK), 0) {
                    toBCommission := TO_B_MODE // toB commission value when commissionData exists
                }
                mstore(
                    add(0x60, commissionInfo),
                    toBCommission //toBCommission
                )
                mstore(
                    add(0x40, commissionInfo),
                    and(commissionData, _ADDRESS_MASK) //token
                )
                // For multiple commission mode, load the encoded commission length and validate
                if gt(referrerNum, 2) {
                    referrerNum := shr(240, and(commissionData, _COMMISSION_LENGTH_MASK))
                    // require(referrerNum >= MIN_COMMISSION_MULTIPLE_NUM && referrerNum <= MAX_COMMISSION_MULTIPLE_NUM, "invalid referrer num")
                    if or(lt(referrerNum, MIN_COMMISSION_MULTIPLE_NUM), gt(referrerNum, MAX_COMMISSION_MULTIPLE_NUM)) {
                        _revertWithReason(
                            0x00000014696e76616c6964207265666572726572206e756d0000000000000000,
                            0x58
                        ) // "invalid referrer num"
                    }
                }
                mstore(add(0x80, commissionInfo), referrerNum) //commissionLength
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
                    ) // "get balanceOf failed"
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
                if and(iszero(eq(to, address())), gt(amount, 0)) {
                    let success := call(gas(), to, amount, 0, 0, 0, 0)
                    if eq(success, 0) {
                        _revertWithReason(
                            0x0000001b636f6d6d697373696f6e2077697468206574686572206572726f7200,
                            0x5f
                        ) // "commission with ether error"
                    }
                }
            }
            function _claimToken(token, _payer, to, amount) {
                if gt(amount, 0) {
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
                        ) // "claim tokens failed"
                    }
                }
            }
            function _sendToken(token, to, amount) {
                if gt(amount, 0) {
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
                    if eq(success, 0) {
                        _revertWithReason(
                            0x0000001b7472616e7366657220746f6b656e2072656665726572206661696c00,
                            0x5f
                        ) // "transfer token referer fail"
                    }
                }
            }
            // get balance, then scale each amount according to balance, and send tokens with scaled amount
            function _sendTokenWithinBalanceAndEmitEvents(token, totalRate, referrerNum, commissionInfo_)
            {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x24))
                mstore(
                    freePtr,
                    0x70a0823100000000000000000000000000000000000000000000000000000000
                ) // balanceOf
                // get token balance of address(this)
                mstore(add(freePtr, 0x4), address())
                let success := staticcall(
                    gas(),
                    token,
                    freePtr,
                    0x24,
                    0,
                    0x20
                )
                if eq(success, 0) {
                    _revertWithReason(
                        0x000000146765742062616c616e63654f66206661696c65640000000000000000,
                        0x58
                    ) // "get balanceOf failed"
                }
                let balanceAfter := mload(0x00)
                let sendAmount := 0 // the amount of tokens already sent
                for { let i := 0 } lt(i, referrerNum) { i := add(i, 1) } {
                    let rate := mload(add(commissionInfo_, add(0xa0, mul(i, 0x40))))
                    let amountScaled
                    switch eq(i, sub(referrerNum, 1))
                    case 1 { // last referrer
                        amountScaled := _safeSub(balanceAfter, sendAmount)
                    }
                    default { // not last referrer
                        amountScaled := _mulDiv(
                            _mulDiv(rate, WAD, totalRate),
                            balanceAfter,
                            WAD
                        )
                        if gt(amountScaled, balanceAfter) {
                            _revertWithReason(
                                0x00000014696e76616c696420616d6f756e745363616c65640000000000000000,
                                0x58
                            ) // "invalid amountScaled"
                        }
                        sendAmount := add(sendAmount, amountScaled)
                    }
                    let referrer := mload(add(commissionInfo_, add(0xc0, mul(i, 0x40))))
                    _sendToken(token, referrer, amountScaled)
                    _emitCommissionFromToken(token, amountScaled, referrer, rate)
                }
            }
            function _emitCommissionFromToken(token, amount, referrer, rate) {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x80))
                mstore(freePtr, token)
                mstore(add(freePtr, 0x20), amount)
                mstore(add(freePtr, 0x40), referrer)
                mstore(add(freePtr, 0x60), rate)
                log1(
                    freePtr,
                    0x80,
                    0xcd5eae9d9d0b96532bd1b7dbf6628ce436b2af735829087a03c548439f8bf850
                ) //emit CommissionFromTokenRecord(address,uint256,address,uint256)
            }

            let token := mload(add(commissionInfo, 0x40))
            let toBCommission := mload(add(commissionInfo, 0x60))
            let totalRate := 0
            let referrerNum := mload(add(commissionInfo, 0x80))
            for { let i := 0 } lt(i, referrerNum) { i := add(i, 1) } {
                let rate := mload(add(commissionInfo, add(0xa0, mul(i, 0x40))))
                totalRate := add(totalRate, rate)
            }
            if gt(totalRate, commissionRateLimit) {
                _revertWithReason(
                    0x000000156572726f7220636f6d6d697373696f6e207261746500000000000000,
                    0x59
                ) // "error commission rate"
            }
            if eq(token, _ETH) { // commission token is ETH, the process is same between no toB mode and toB mode
                for { let i := 0 } lt(i, referrerNum) { i := add(i, 1) } {
                    let rate := mload(add(commissionInfo, add(0xa0, mul(i, 0x40))))
                    let referrer := mload(add(commissionInfo, add(0xc0, mul(i, 0x40))))
                    let amount := div(
                        mul(inputAmount, rate),
                        sub(DENOMINATOR, totalRate)
                    )
                    _sendETH(referrer, amount)
                    _emitCommissionFromToken(_ETH, amount, referrer, rate)
                }
            }
            if and(iszero(eq(token, _ETH)), eq(toBCommission, NO_TO_B_MODE)) { // commission token is ERC20 with no toB mode
                for { let i := 0 } lt(i, referrerNum) { i := add(i, 1) } {
                    let rate := mload(add(commissionInfo, add(0xa0, mul(i, 0x40))))
                    let referrer := mload(add(commissionInfo, add(0xc0, mul(i, 0x40))))
                    let amount := div(
                        mul(inputAmount, rate),
                        sub(DENOMINATOR, totalRate)
                    )
                    _claimToken(token, payer, referrer, amount)
                    _emitCommissionFromToken(token, amount, referrer, rate)
                }
            }
            if and(iszero(eq(token, _ETH)), eq(toBCommission, TO_B_MODE)) { // commission token is ERC20 with toB mode
                let totalAmount := div(
                    mul(inputAmount, totalRate),
                    sub(DENOMINATOR, totalRate)
                )
                _claimToken(token, payer, address(), totalAmount)
                _sendTokenWithinBalanceAndEmitEvents(
                    token,
                    totalRate,
                    referrerNum,
                    commissionInfo
                )
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
                let success := call(NATIVE_TOKEN_TRANSFER_GAS_LIMIT, to, amount, 0, 0, 0, 0)
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
                            0x0000001173656e64206574686572206661696c65640000000000000000000000,
                            0x55
                        ) // "send ether failed"
                    }
                }
            }
            function _sendToken(token, to, amount) {
                if gt(amount, 0) {
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
                    if eq(success, 0) {
                        _revertWithReason(
                            0x000000157472616e7366657220746f6b656e206661696c656400000000000000,
                            0x59
                        ) // "transfer token failed"
                    }
                }
            }
            function _emitCommissionToToken(token, amount, referrer, rate) {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x80))
                mstore(freePtr, token)
                mstore(add(freePtr, 0x20), amount)
                mstore(add(freePtr, 0x40), referrer)
                mstore(add(freePtr, 0x60), rate)
                log1(
                    freePtr,
                    0x80,
                    0x3cfb523a4c38d88561dd3bf04805a31715c8b5fc468a03b8d684356f360dea99
                ) //emit CommissionToTokenRecord(address,uint256,address,uint256)
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
            }

            // require(balanceAfter > balanceBefore, "invalid balance after");
            if or(gt(balanceBefore, balanceAfter), eq(balanceAfter, balanceBefore)) {
                _revertWithReason(
                    0x00000015696e76616c69642062616c616e636520616674657200000000000000,
                    0x59
                ) // "invalid balance after"
            }
            let inputAmount := sub(balanceAfter, balanceBefore)

            // process commission
            let flag := mload(add(commissionInfo, 0x20)) // commissionInfo.isToTokenCommission
            if gt(flag, 0) { // commissionInfo.isToTokenCommission == True
                let commissionAmount := _processCommission(commissionInfo, toToken, inputAmount)
                inputAmount := sub(inputAmount, commissionAmount)
                totalAmount := commissionAmount
            }

            // process trim
            flag := mload(add(trimInfo, 0x00)) // trimInfo.hasTrim
            let expectAmountOut := mload(add(trimInfo, 0x80)) // trimInfo.expectAmountOut
            if and(gt(flag, 0), gt(inputAmount, expectAmountOut)) { // trimInfo.hasTrim == True && inputAmount > trimInfo.expectAmountOut
                let trimAmount := _processTrim(trimInfo, toToken, inputAmount)
                inputAmount := sub(inputAmount, trimAmount)
                totalAmount := add(totalAmount, trimAmount)
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
                _sendToken(toToken, shr(96, shl(96, receiver)), inputAmount)
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
                let success := call(NATIVE_TOKEN_TRANSFER_GAS_LIMIT, to, amount, 0, 0, 0, 0)
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

        // Validate commission recipient addresses to prevent accidental burns.
        if (commissionInfo.isFromTokenCommission || commissionInfo.isToTokenCommission) {
            require(commissionInfo.refererAddress != address(0), "Invalid referrer");
            if (commissionInfo.commissionRate2 > 0) {
                require(commissionInfo.refererAddress2 != address(0), "Invalid referrer2");
            }
        }
        
        require(
            (commissionInfo.isFromTokenCommission && commissionInfo.token == fromToken)
                || (commissionInfo.isToTokenCommission && commissionInfo.token == toToken)
                || (!commissionInfo.isFromTokenCommission && !commissionInfo.isToTokenCommission),
            "Invalid commission info"
        );
    }

    function _validateTrimInfo(TrimInfo memory trimInfo) internal pure {
        if (!trimInfo.hasTrim) return;

        // Validate trim/charge recipient addresses to prevent accidental burns.
        if (trimInfo.chargeRate < TRIM_DENOMINATOR) { // Not all trim is charged, so trimAddress should not be zero
            require(trimInfo.trimAddress != address(0), "Invalid trimAddress");
        }
        if (trimInfo.chargeRate > 0) {
            require(trimInfo.chargeAddress != address(0), "Invalid chargeAddress");
        }
    }
}