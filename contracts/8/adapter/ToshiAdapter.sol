// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";

struct SwapParams {
    address inputToken;
    address outputToken;
    uint256 inputAmount;
    uint256 minOutputAmount;
    bytes permitData;
}

interface IToshi {
    function swapExactInput(SwapParams calldata params) external payable returns (uint256 out0);
}

contract ToshiAdapter is IAdapter {
    address public immutable WNATIVE;

    event Received(address sender, uint256 amount);

    constructor(address wnative) {
        WNATIVE = wnative;
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
            IERC20(token).transfer(receiver, amount);
        }
    }

    function _toshiSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));
        
        uint256 inputAmount;
        bool isFromTokenETH = (fromToken == WNATIVE);
        bool isToTokenETH = (toToken == address(0)); // moreInfo中的toToken为address(0)表示ETH输出
        
        if (isFromTokenETH) {
            // Handle WETH input - convert to ETH
            inputAmount = IERC20(WNATIVE).balanceOf(address(this));
            require(inputAmount > 0, "ToshiAdapter: INSUFFICIENT_INPUT");
            IWETH(WNATIVE).withdraw(inputAmount);
        } else {
            // Handle ERC20 input
            inputAmount = IERC20(fromToken).balanceOf(address(this));
            require(inputAmount > 0, "ToshiAdapter: INSUFFICIENT_INPUT");
            IERC20(fromToken).approve(pool, inputAmount);
        }

        SwapParams memory params = SwapParams({
            inputToken: isFromTokenETH ? address(0) : fromToken,
            outputToken: toToken,
            inputAmount: inputAmount,
            minOutputAmount: 0,
            permitData: ""
        });

        if (isFromTokenETH) {
            // ETH to ERC20 swap
            IToshi(pool).swapExactInput{value: inputAmount}(params);
        } else {
            // ERC20 to ERC20 or ERC20 to ETH swap
            IToshi(pool).swapExactInput(params);
        }

        // Transfer output tokens to recipient
        if (isToTokenETH) {
            // Handle ETH output - wrap to WETH for compatibility with test framework
            uint256 ethBalance = address(this).balance;
            if (ethBalance > 0) {
                // Wrap ETH to WETH and transfer
                IWETH(WNATIVE).deposit{value: ethBalance}();
                IERC20(WNATIVE).transfer(to, ethBalance);
            }
        } else {
            // Handle ERC20 output
            uint256 outputBalance = IERC20(toToken).balanceOf(address(this));
            if (outputBalance > 0) {
                IERC20(toToken).transfer(to, outputBalance);
            }
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _toshiSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _toshiSwap(to, pool, moreInfo);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}