// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IMaverickV2.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/TickMath.sol";


/// @title UniV3Adapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract MaverickV2Adapter is IAdapter {

    function _maverickV2Swap(address to, address pool, bytes memory data) internal {
        (address fromToken, address toToken) = abi.decode(data, (address, address));
        // zeroForOne is true, then fromToken < toToken, fromToken is TokenA, tokenAIn is true
        // zeroForOne is fale, then fromToken > toToken, fromToken is not TokenA, tokenAIn is false
        bool zeroForOne = fromToken < toToken;

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));

        IPool.SwapParams memory params = IPool.SwapParams({
            amount: sellAmount,
            tokenAIn: zeroForOne,
            exactOutput: false,
            tickLimit: zeroForOne ? type(int32).max : type(int32).min
        });

        SafeERC20.safeTransfer(IERC20(fromToken), pool, sellAmount);
        IPool(pool).swap(
            to,
            params,
            ""
        );
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _maverickV2Swap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _maverickV2Swap(to, pool, moreInfo);
    }

}
