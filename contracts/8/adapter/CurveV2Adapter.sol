// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ICurveV2.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "hardhat/console.sol";

contract CurveV2Adapter is IAdapter {

    function _curveSwap(address to, address pool, bytes memory moreInfo) internal {
        
        (address fromToken, address toToken, uint256 i, uint256 j) = abi.decode(moreInfo, (address, address, uint256, uint256));


       uint256 sellAmount = 0;
        uint256 sendValue = 0;
        if(sourceToken == ETH_ADDRESS) {
            sellAmount = IWETH(WETH_ADDRESS).balanceOf(address(this));
            IWETH(WETH_ADDRESS).withdraw(sellAmount);
            sendValue = sellAmount;
        } else {
            sellAmount = IERC20(sourceToken).balanceOf(address(this));
            // approve
            IERC20(sourceToken).approve(BANCOR_ADDRESS, sellAmount);
        }



        if (use_eth) {
             sellAmount = address(this).balance;
        } else {
            // // approve
            sellAmount = IERC20(fromToken).balanceOf(address(this));
            SafeERC20.safeApprove(IERC20(fromToken),  pool, sellAmount);
        }

        console.log("sellAmount: ", sellAmount);
        // // swap
        ICurveV2(pool).exchange(i, j, sellAmount, 0);
        
        // approve 0
        SafeERC20.safeApprove(IERC20(sourceToken == ETH_ADDRESS ? WETH_ADDRESS : sourceToken), BANCOR_ADDRESS, 0);
        if(to != address(this)) {
            if(targetToken == ETH_ADDRESS) {
                IWETH(WETH_ADDRESS).deposit{ value: returnAmount }();
                targetToken = WETH_ADDRESS;
            }
            SafeERC20.safeTransfer(IERC20(targetToken), to, IERC20(targetToken).balanceOf(address(this)));
        }
    }

    // function sellQuote2(address to, address pool, bytes memory moreInfo) external {
    //     (address fromToken, address toToken, int128 i, int128 j, bool use_eth) = abi.decode(moreInfo, (address, address, int128, int128, bool));
    //     uint256 sellAmount;
    //     if (use_eth) {
    //          sellAmount = address(this).balance;
    //     } else {
    //         // // approve
    //         sellAmount = IERC20(fromToken).balanceOf(address(this));
    //         SafeERC20.safeApprove(IERC20(fromToken),  pool, sellAmount);
    //     }

    //     console.log("sellAmount: ", sellAmount);
    //     console.log("pool address: ", pool);
    //     console.logInt(i);
    //     console.logInt(j);

    //     // // swap
    //     ICurveV2(pool).exchange{value: sellAmount}(i, j, sellAmount, 0);
        
    //     if(to != address(this)) {
    //         SafeERC20.safeTransfer(IERC20(toToken), to, IERC20(toToken).balanceOf(address(this)));
    //     }
    // }

    

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _curveSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _curveSwap(to, pool, moreInfo);
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}