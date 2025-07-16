// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ICurveTriOpt.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract CurveTriOptAdapter is IAdapter {
    function _curveSwap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken, uint256 i, uint256 j) =
            abi.decode(moreInfo, (address, address, uint256, uint256));

        // check params
        require(fromToken == ICurveTriOpt(pool).coins(i), "CurveTriOptAdapter: fromToken not match");
        require(toToken == ICurveTriOpt(pool).coins(j), "CurveTriOptAdapter: toToken not match");

        // approve sellAmount
        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);
        
        // swap
        ICurveTriOpt(pool).exchange(i, j, sellAmount, 0, to);
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _curveSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _curveSwap(to, pool, moreInfo);
    }
}
