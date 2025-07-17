// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IUni.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IFewERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IFewWrappedToken.sol";

/// @title RingAdapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract RingAdapter is IAdapter {

    function _wrapAndTransfer(address tokenIn, address fwTokenIn, address pool) internal{
        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(tokenIn), fwTokenIn, amountIn);
        IFewWrappedToken(fwTokenIn).wrapTo(amountIn, pool);
    }
    
    function _unwrapAndTransfer(address fwTokenOut, address to) internal {
        IFewWrappedToken(fwTokenOut).unwrapTo(IFewERC20(fwTokenOut).balanceOf(address(this)), to);
    }
    
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (address tokenIn) = abi.decode(moreInfo, (address));
        address baseToken = IUni(pool).token0();
        _wrapAndTransfer(tokenIn, baseToken, pool);
        
        (uint256 reserveIn, uint256 reserveOut, ) = IUni(pool).getReserves();
        require(reserveIn > 0 && reserveOut > 0, "RingAdapter: INSUFFICIENT_LIQUIDITY");
        uint256 sellBaseAmountWithFee = (IERC20(baseToken).balanceOf(pool) - reserveIn) * 997;
        uint256 receiveQuoteAmount = (sellBaseAmountWithFee * reserveOut) / (reserveIn * 1000 + sellBaseAmountWithFee);
        IUni(pool).swap(0, receiveQuoteAmount, address(this), new bytes(0));

        _unwrapAndTransfer(IUni(pool).token1(), to);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (address tokenIn) = abi.decode(moreInfo, (address));
        address quoteToken = IUni(pool).token1();
        _wrapAndTransfer(tokenIn, quoteToken, pool);

        (uint256 reserveOut, uint256 reserveIn, ) = IUni(pool).getReserves();
        require(reserveIn > 0 && reserveOut > 0, "RingAdapter: INSUFFICIENT_LIQUIDITY");
        uint256 sellQuoteAmountWithFee = (IERC20(quoteToken).balanceOf(pool) - reserveIn) * 997;
        uint256 receiveBaseAmount = (sellQuoteAmountWithFee * reserveOut) / (reserveIn * 1000 + sellQuoteAmountWithFee);
        IUni(pool).swap(receiveBaseAmount, 0, address(this), new bytes(0));

        _unwrapAndTransfer(IUni(pool).token0(), to);
    }
}