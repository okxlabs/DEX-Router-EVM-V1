// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IUnswapRouter02.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

contract BabyDogeAdapter is IAdapter {
    address immutable router;
    address immutable WETH;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _router) {
        router = _router;
        WETH = IUnswapRouter02(_router).WETH();
    }

    function _swap(address to, address, bytes memory moreInfo) internal {
        (address fromToken, address toToken) =
            abi.decode(moreInfo, (address, address));

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

        IUnswapRouter02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, 0, path, to, type(uint256).max);
    }

    function sellBase(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _swap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _swap(to, pool, moreInfo);
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
    }
}