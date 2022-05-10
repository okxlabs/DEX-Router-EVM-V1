// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockBancor {
    uint256 public tokenReserveBalance = 0;
    uint32 public tokenConversionFee = 0;

    function reserveBalance(
        address /*reserveToken*/
    ) public view returns (uint256) {
        return tokenReserveBalance;
    }

    function conversionFee() external view returns (uint32) {
        return tokenConversionFee;
    }

    function setConversionFee(uint32 fee) external {}
}
