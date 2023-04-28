// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IIron.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ILendingPool.sol";

import "../libraries/SafeERC20.sol";

contract Ironswap3PoolLpAdapter is IAdapter {
    address immutable LP_TOKEN_ADDRESS;
    address immutable threePool;
    uint256 constant POOL_TOKEN_AMOUNT = 3;

    constructor(address _threePool) {
        threePool = _threePool;
        LP_TOKEN_ADDRESS = IIron(threePool).getLpToken();
        require(LP_TOKEN_ADDRESS != address(0), "misconfigure the three pool address");
    }

    // fromToken == LP
    function sellBase(address to, address, bytes memory moreInfo) external override {
        (address toToken) = abi.decode(moreInfo, (address));
        uint256 lpTokenAmount = IERC20(LP_TOKEN_ADDRESS).balanceOf(address(this));
        uint8 toTokenIndex = IIron(threePool).getTokenIndex(toToken);
        IERC20(LP_TOKEN_ADDRESS).approve(threePool, lpTokenAmount);
        IIron(threePool).removeLiquidityOneToken(
            lpTokenAmount, toTokenIndex, 0, block.timestamp
        );
        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(toToken), to, IERC20(toToken).balanceOf(address(this))
            );
        }
    }
    // fromToken == tokens

    function sellQuote(address to, address, bytes memory moreInfo) external override {
        (address fromToken) = abi.decode(moreInfo, (address));
        uint256 fromTokenAmount = IERC20(fromToken).balanceOf(address(this));
        uint8 fromTokenIndex = IIron(threePool).getTokenIndex(fromToken);
        uint256[] memory amounts = new uint[](POOL_TOKEN_AMOUNT);
        amounts[fromTokenIndex] = fromTokenAmount;
        SafeERC20.safeApprove(IERC20(fromToken), threePool, fromTokenAmount);
        IIron(threePool).addLiquidity(amounts, 0, block.timestamp);
        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(LP_TOKEN_ADDRESS),
                to,
                IERC20(LP_TOKEN_ADDRESS).balanceOf(address(this))
            );
        }
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
    }
}
