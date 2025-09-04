// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/IVirtuals.sol";

//virtuals internal trading
contract VirtualsAdapter is IAdapter {

    address public immutable BONDING;//0xf66dea7b3e897cd44a5a231c61b6b4423d613259
    address public immutable VIRTUALTOKEN;//0x0b3e328455c4059EEb9e3f84b5543F74E24e7E1b
    address public immutable FROUTER;//0x8292B43aB73EfAC11FAF357419C38ACF448202C5

    constructor (
        address bonding,
        address virtualToken,
        address FRouter
    ) {
        BONDING = bonding;
        VIRTUALTOKEN = virtualToken;
        FROUTER = FRouter;
    }

    function _virtualsTrading(
        address to,
        bytes memory moreInfo
    ) private {
        uint256 amountIn;
        uint256 amountOut;
        (address tokenAddress, bool buyMeme) = abi.decode(
            moreInfo,
            (address, bool)
        );

        if (buyMeme) {
            amountIn = IERC20(VIRTUALTOKEN).balanceOf(address(this));
            IERC20(VIRTUALTOKEN).approve(FROUTER, amountIn);
            IBonding(BONDING).buy(amountIn, tokenAddress);
            amountOut = IERC20(tokenAddress).balanceOf(address(this));
            IERC20(tokenAddress).transfer(to, amountOut);
        } else {
            amountIn = IERC20(tokenAddress).balanceOf(address(this));
            IERC20(tokenAddress).approve(FROUTER, amountIn);
            IBonding(BONDING).sell(amountIn, tokenAddress);
            amountOut = IERC20(VIRTUALTOKEN).balanceOf(address(this));
            IERC20(VIRTUALTOKEN).transfer(to, amountOut);
        }
    }

    function sellBase(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        _virtualsTrading(to,moreInfo);
    }

    function sellQuote(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        _virtualsTrading(to, moreInfo);
    }
}
