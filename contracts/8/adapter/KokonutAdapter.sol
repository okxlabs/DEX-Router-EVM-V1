// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IKokonutSwap.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";


contract KokonutAdapter is IAdapter {
    function _KokonutSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (
            address fromToken, 
            address toToken,
            uint256 tokenIndexFrom,
            uint256 tokenIndexTo
        ) = abi.decode(moreInfo, (address, address, uint256, uint256));

        require(fromToken == IKokonutSwapPool(pool).coins(tokenIndexFrom) , "not correct index");
        require(tokenIndexFrom + tokenIndexTo == 1 , "not correct");

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        // approve
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);

        // swap
        uint256 amountOut ;
        (amountOut,) = IKokonutSwapPool(pool).exchange(tokenIndexFrom,tokenIndexTo,sellAmount,1,"");
     
        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(toToken),
                to,
                amountOut//
            );
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _KokonutSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _KokonutSwap(to, pool, moreInfo);
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
    }
}

