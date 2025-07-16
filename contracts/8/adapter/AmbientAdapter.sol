// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IAmbient.sol";

contract AmbientAdapter is IAdapter {

    address immutable CrocSwapDex;

    constructor(
        address _CrocSwapDex
    ) {
        //the only interacted contract
        CrocSwapDex = _CrocSwapDex;
    }

    function _crocSwap(
        address to,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken) = abi.decode(
            moreInfo,
            (address, address)
        );

        (address base, address quote) = fromToken < toToken ? (fromToken, toToken) : (toToken, fromToken);

        uint256 inputAmount = IERC20(fromToken).balanceOf(address(this));

        //Approve
        SafeERC20.safeApprove(
            IERC20(fromToken),
            address(CrocSwapDex),
            inputAmount
        );

        //Swap
        //Currently Ambient only has one pool type index initialized and it is 420
        if(fromToken == base){
            IAmbient(CrocSwapDex).swap(base, quote, 420, true, true, uint128(inputAmount), 0, type(uint128).max, 0, 0);
        } else {
            IAmbient(CrocSwapDex).swap(base, quote, 420, false, false, uint128(inputAmount), 0, 0, 0, 0);
        }

        if(to != address(this)){
            SafeERC20.safeTransfer(IERC20(toToken), to, IERC20(toToken).balanceOf(address(this)));
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _crocSwap(to, moreInfo);

    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _crocSwap(to, moreInfo);
    }

}