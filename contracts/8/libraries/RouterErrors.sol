// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// RouterErrors: Centralized custom errors for DexRouter and related contracts

// ========== DexRouter Errors ==========
error DexRouter_Expired();
error DexRouter_TotalWeightMustBe10000();
error DexRouter_FirstTokenMismatch();
error DexRouter_TotalBatchAmountExceeded();
error DexRouter_LengthMismatch();
error DexRouter_InconsistentFromToken();
error DexRouter_InvalidSourceToken();
error DexRouter_RefundToIsZeroAddress();
error DexRouter_ToIsZeroAddress();
error DexRouter_FromTokenAmountIsZero();
error DexRouter_MinReturnNotReached();
error DexRouter_UnxswapTokenMismatch();
error DexRouter_UniswapV3TokenMismatch();
error DexRouter_UnxswapFromTokenMismatch();
error DexRouter_UnxswapToTokenMismatch();
error DexRouter_AmountMustBePositive();
error DexRouter_TrimNotSupportedInSwapWrap();
error DexRouter_TransferNativeTokenFailed();
error DexRouter_ValueNotEqualAmount();
error DexRouter_InvalidTokenPair();
error DexRouter_PathsMustBePositive();

// ========== DagRouter Errors ==========
error DagRouter_FirstTokenMismatch();
error DagRouter_ValueMustBeZero();
error DagRouter_EdgeLengthMustBePositive();
error DagRouter_PathLengthMismatch();
error DagRouter_NodeBalanceMustBePositive();
error DagRouter_NodeInputIndexInconsistent();
error DagRouter_NodeIndexOutOfRange();
error DagRouter_TotalWeightMustBe10000();

// ========== CommissionLib Errors ==========
error Commission_InvalidBalanceAfter();
error Commission_RateLimitExceeded();
error Commission_TrimRateLimitExceeded();
error Commission_InvalidChargeRate();
error Commission_FromTokenCommissionNotSupported();
error Commission_InvalidTokens();
error Commission_InvalidCommissionDirection();
error Commission_InvalidReferrer();
error Commission_InvalidReferrer2();
error Commission_InvalidCommissionInfo();
error Commission_InvalidTrimAddress();
error Commission_InvalidChargeAddress();

// ========== CommonLib Errors ==========
error CommonLib_AdaptorCallFailed();
error CommonLib_Permit2ModeNotSupported();
error CommonLib_TransferNativeTokenFailed();
error CommonLib_RefundETHFailed();
