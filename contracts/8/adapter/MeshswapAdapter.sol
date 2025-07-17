// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IMeshswapRouter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

contract MeshswapAdapter is IAdapter {
    address immutable router;
    address immutable WETH;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _router) {
        router = _router;
        WETH = IMeshswapRouter(router).WETH();
        require(WETH != address(0), "router misconfigured");
    }

    function _meshswap(address to, address, bytes memory moreInfo) internal {
        (address fromToken, address toToken, uint256 deadline) =
            abi.decode(moreInfo, (address, address, uint256));

        if (fromToken == ETH_ADDRESS) {
            fromToken = WETH;
        } else if (toToken == ETH_ADDRESS) {
            toToken = WETH;
        }
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;
        uint256 amountIn = IERC20(fromToken).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(fromToken), router, amountIn);

        IMeshswapRouter(router).swapExactTokensForTokens(amountIn, 0, path, to, deadline);
    }

    function sellBase(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _meshswap(to, pool, moreInfo);
    }
    // fromToken = token1

    function sellQuote(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _meshswap(to, pool, moreInfo);
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
    }
}
