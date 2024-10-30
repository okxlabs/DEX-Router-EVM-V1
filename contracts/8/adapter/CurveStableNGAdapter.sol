
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ICurveStableNG.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract CurveStableNGAdapter is IAdapter {
    function _curveSwap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken, int128 i, int128 j) =
            abi.decode(moreInfo, (address, address, int128, int128));

        // check params
        require(fromToken == ICurveStableNG(pool).coins(uint256(uint128(i))), "CurveStableNGAdapter: fromToken not match");
        require(toToken == ICurveStableNG(pool).coins(uint256(uint128(j))), "CurveStableNGAdapter: toToken not match");

        // approve sellAmount
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);

        // swap
        //Attention: not use exchange_received here in case of rebase token
        ICurveStableNG(pool).exchange(i, j, sellAmount, 0, to);
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _curveSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _curveSwap(to, pool, moreInfo);
    }
}