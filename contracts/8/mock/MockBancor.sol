// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockBancor {

    function reserveBalance(address reserveToken) public view returns (uint256) {
        return 0;
    }

    function conversionFee() external view returns (uint32) {
        return 0;
    }
}