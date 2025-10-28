pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/// @title Callback for IDODOV3PoolActions #sellToken & buyToken
/// @notice Any contract that calls IDODOV3PoolActions #sellToken & buyToken must implement this interface
interface IDODOSwapCallback {
    function d3MMSwapCallBack(address token, uint256 value, bytes calldata data) external;
}