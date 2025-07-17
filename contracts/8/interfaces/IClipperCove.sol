// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IClipperCove {
    function sellTokenForToken(
        address sellToken, 
        address buyToken, 
        uint256 minBuyAmount, 
        address destinationAddress, 
        bytes32 auxData
    ) external returns (uint256 buyAmount);
}

