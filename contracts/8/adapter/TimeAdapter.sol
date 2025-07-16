// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ITime.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

/// @title TimeAdapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract TimeAdapter is IAdapter {
    address public immutable TIME;
    address public immutable usd1;
    address public immutable usd2;
    address public immutable usd3;

    constructor (
        address _TIME,
        address _usd1,
        address _usd2,
        address _usd3
    ) {
        TIME = _TIME;
        usd1 = _usd1;
        usd2 = _usd2;
        usd3 = _usd3;
    }

    // fromToken == TIME
    function sellBase(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        (address tokenIn, address tokenOut) = abi.decode(moreInfo, (address, address));
        uint256 amount = IERC20(TIME).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(TIME),
            TIME,
            amount
        );
        ITime(TIME).Sell(tokenOut, amount);
        SafeERC20.safeTransfer(
            IERC20(tokenOut), 
            to, 
            IERC20(tokenOut).balanceOf(address(this))
        );
    }

    // fromToken == usd
    function sellQuote(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        (address tokenIn, address tokenOut) = abi.decode(moreInfo, (address, address));
        uint256 amount = IERC20(tokenIn).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(tokenIn),
            TIME,
            amount
        );
        ITime(TIME).Buy(tokenIn, amount);
        SafeERC20.safeTransfer(
            IERC20(TIME), 
            to, 
            IERC20(TIME).balanceOf(address(this))
        );
    }
}
