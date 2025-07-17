// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IFluid.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";
contract FluidAdapter is IAdapter {
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address WETH;
    constructor(address _weth) {
        WETH = _weth;
    }

    function _FluidSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address tokenIn, address tokenOut) = abi.decode(
            moreInfo,
            (address, address)
        );
        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
        tokenIn = _getAddress(tokenIn);
        if (tokenIn == ETH) {
            IWETH(WETH).withdraw(amountIn);
        } else {
            SafeERC20.safeApprove(IERC20(tokenIn), pool, amountIn);
        }
        Structs.ConstantViews memory views = IFluidDex(pool).constantsView();
        address token0 = views.token0;
        bool isToken0In = tokenIn == token0;
        uint amountValue = tokenIn == ETH ? amountIn : 0;
        IFluidDex(pool).swapIn{value: amountValue}(isToken0In, amountIn, 0, to);
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _FluidSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _FluidSwap(to, pool, moreInfo);
    }

    function _getAddress(address token) internal view returns (address) {
        if (token == WETH) return ETH;
        return token;
    }
}
