// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IUni.sol";
import "../interfaces/IERC20.sol";

/// @title TestAdapter
/// @notice Test adapter for testing revert
/// @dev Test adapter for testing revert
contract TestRevertAdapter is IAdapter {
    error TestRevertAdapterError1();
    error TestRevertAdapterError2(uint256);
    error TestRevertAdapterError3(uint256, uint256);
    error TestRevertAdapterError4(string);

    function _revert(bytes memory moreInfo) internal pure {
        uint256 flag = abi.decode(moreInfo, (uint256));
        if (flag == 1) {
            revert TestRevertAdapterError1();
        } else if (flag == 2) {
            revert TestRevertAdapterError2(100);
        } else if (flag == 3) {
            revert TestRevertAdapterError3(100, 101);
        } else if (flag == 4) {
            revert TestRevertAdapterError4("test revert");
        } else if (flag == 5) {
            revert("test revert");
        } else if (flag == 6) {
            require(false, "test require");
        } else {
            uint256 a = 1;
            a = a - 2; // arithmetic overflow
        }
    }

    function sellBase(
        address,
        address,
        bytes memory moreInfo
    ) external override {
        _revert(moreInfo);
    }

    function sellQuote(
        address,
        address,
        bytes memory moreInfo
    ) external override {
        _revert(moreInfo);
    }
}