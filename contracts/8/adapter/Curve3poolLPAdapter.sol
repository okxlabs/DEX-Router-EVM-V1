// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import {ICurve} from "../interfaces/ICurve.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract Curve3poolLPAdapter is IAdapter {
    address public immutable LP_TOKEN_ADDRESS ;
    uint256 constant POOL_TOKEN_AMOUNT= 3;

    constructor(address lp_token_address) {
        LP_TOKEN_ADDRESS = lp_token_address;
    }

    // fromToken == LP_TOKEN_ADDRESS
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        // get arguments
        (int128 toTokenIndex) = abi.decode(moreInfo, (int128));
        uint256 tokenAmount = IERC20(LP_TOKEN_ADDRESS).balanceOf(address(this));
        address toToken = ICurve(pool).coins(uint256(int256(toTokenIndex)));

        // approve and remove liquidity
        SafeERC20.safeApprove(IERC20(LP_TOKEN_ADDRESS), pool, tokenAmount);
        ICurve(pool).remove_liquidity_one_coin(tokenAmount,toTokenIndex,0);

        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(toToken),
                to,
                IERC20(toToken).balanceOf(address(this))
            );
        }
    }

    // from == tokens
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        // get arguments
        (int128 fromTokenIndex) = abi.decode(moreInfo, (int128));
        address fromToken = ICurve(pool).coins(uint256(int256(fromTokenIndex)));
        uint256 fromTokenAmount = IERC20(fromToken).balanceOf(address(this));

        // get tokens amounts
        uint256[POOL_TOKEN_AMOUNT] memory amounts = [uint256(0), uint256(0), uint256(0)];
        amounts[uint256(int256(fromTokenIndex))] = fromTokenAmount;

        // approve and add liquidity
        SafeERC20.safeApprove(IERC20(fromToken), pool, fromTokenAmount);
        ICurve(pool).add_liquidity(
            amounts,
            0
        );

        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(LP_TOKEN_ADDRESS),
                to,
                IERC20(LP_TOKEN_ADDRESS).balanceOf(address(this))
            );
        }
    }
}
