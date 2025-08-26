// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAaveLendingPool.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IPortal.sol";
import "../types/ExactInputParams.sol";

// only for ETH
contract FlapAdapter is IAdapter {

    address public immutable FLAP_PORTAL;
    address public immutable WNATIVE;

    constructor (
        address flapPortal,
        address wnative
    ) {
        FLAP_PORTAL = flapPortal;
        WNATIVE = wnative;
    }

    function _flapSwap(
        address to,
        address , // pool parameter not used for Flap Portal
        bytes memory moreInfo
    ) internal {

        (ExactInputParams memory params) = abi.decode(moreInfo, (ExactInputParams));
        
        // Track if we need to wrap output to WNATIVE
        bool shouldWrapOutput = params.outputToken == WNATIVE;

        if (params.inputToken == WNATIVE) { 
            // WNATIVE -> FlapToken: unwrap to NATIVE for swap
            uint256 wethBalance = IERC20(WNATIVE).balanceOf(address(this));
            if (wethBalance > 0) {
                IWETH(WNATIVE).withdraw(wethBalance);
                params.inputToken = address(0); // update inputToken to NATIVE
                params.inputAmount = wethBalance;
            }
        } 
        
        if (shouldWrapOutput) {
            // FlapToken -> NATIVE: Set output to NATIVE, will wrap after swap
            params.outputToken = address(0); // update outputToken to NATIVE
        }

        // Execute swap with portal
        if (params.inputToken == address(0)) {
            // NATIVE input - send NATIVE value with call
            IPortal(FLAP_PORTAL).swapExactInput{value: params.inputAmount}(params);
        } else {
            // ERC20 input - approve and swap FlapToken
            IERC20(params.inputToken).approve(FLAP_PORTAL, params.inputAmount);
            IPortal(FLAP_PORTAL).swapExactInput(params);
        }

        // If original output was WNATIVE, wrap the received OKB
        if (shouldWrapOutput) {
            uint256 ethBalance = address(this).balance;
            if (ethBalance > 0) {
                IWETH(WNATIVE).deposit{value: ethBalance}();
            }
        }

        // Transfer output tokens to recipient
        if (shouldWrapOutput) {
            // Output was WNATIVE - transfer wrapped tokens to recipient
            uint256 wnativeBalance = IERC20(WNATIVE).balanceOf(address(this));
            if (wnativeBalance > 0) {
                SafeERC20.safeTransfer(IERC20(WNATIVE), to, wnativeBalance);
            }
        } else {
            // Output is FlapToken
            uint256 tokenBalance = IERC20(params.outputToken).balanceOf(address(this));
            if (tokenBalance > 0) {
                SafeERC20.safeTransfer(IERC20(params.outputToken), to, tokenBalance);
            }
        }

        // Handle any remaining dust (leftover native ETH) - should be minimal after main transfer
        uint256 dust = address(this).balance;
        if (dust > 0) {
            (bool success, ) = to.call{value: dust}("");
            require(success, "Dust transfer failed");
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _flapSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _flapSwap(to, pool, moreInfo);
    }

    function _getBalance(address token, address user) internal view returns (uint256) {
        if (token == address(0)) {
            return address(user).balance;
        } else {
            return IERC20(token).balanceOf(user);
        }
    }

    function _safeTransfer(address token, address receiver, uint256 amount) internal {
        if (token == address(0)) {
            (bool success, ) = payable(receiver).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(token), receiver, amount);
        }
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}
