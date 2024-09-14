// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IRabbitRouter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

/// @title BunnyswapAdapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract BunnyswapAdapter is IAdapter {
    address public immutable router;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant FRIEND = 0x0bD4887f7D41B35CD75DFF9FfeE2856106f86670;

    constructor (
        address _router
    ) {
        router = _router;
    }

    // fromToken == token0(FRIEND)
    function sellBase(
        address to,
        address,
        bytes memory
    ) external override {
        uint amountIn = IERC20(FRIEND).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(FRIEND),
            router,
            amountIn
        );
        IRabbitRouter(router).swapExactTokensForETH(amountIn, 0, address(this), block.timestamp);
        IWETH(WETH).deposit{ value: address(this).balance }();
        SafeERC20.safeTransfer(IERC20(WETH), to, IERC20(WETH).balanceOf(address(this)));
    }

    // fromToken == token1(WETH)
    function sellQuote(
        address to,
        address,
        bytes memory
    ) external override {
        uint amountIn = IERC20(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amountIn);
        IRabbitRouter(router).swapExactETHForTokens{ value: amountIn }(0, to, block.timestamp);
    }

    receive() external payable {
        assert(msg.sender == WETH || msg.sender == router);
    }
}