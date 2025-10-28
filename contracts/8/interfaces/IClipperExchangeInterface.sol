// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Clipper interface subset used in swaps
interface IClipperExchangeInterface {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function sellEthForToken(address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external payable;
    function sellTokenForEth(address inputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external;
    function swap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external;
}