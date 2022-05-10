// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapterWithResult.sol";
import "../interfaces/IMarketMaker.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IApproveProxy.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract PMMAdapter is IAdapterWithResult {
    address public immutable marketMaker;
    address public immutable dexRouter;

    constructor(address _marketMaker, address _dexRouter) {
        marketMaker = _marketMaker;
        dexRouter = _dexRouter;
    }

    function _pmmSwap(
        address to,
        address, /*pool*/
        bytes memory moreInfo
    ) internal returns (uint256) {
        IMarketMaker.PMMSwapRequest memory request = abi.decode(
            moreInfo,
            (IMarketMaker.PMMSwapRequest)
        );

        uint256 sellAmount = IERC20(request.fromToken).balanceOf(address(this));

        // approve
        address approveProxy = IMarketMaker(marketMaker).approveProxy();
        address tokenApprove = IApproveProxy(approveProxy).tokenApprove();
        SafeERC20.safeApprove(
            IERC20(request.fromToken),
            tokenApprove,
            sellAmount
        );

        uint256 result = IMarketMaker(marketMaker).swap(sellAmount, request);

        // refund
        uint256 fromBal = IERC20(request.fromToken).balanceOf(address(this));
        if (fromBal > 0) {
            SafeERC20.safeTransfer(
                IERC20(request.fromToken),
                to,
                IERC20(request.fromToken).balanceOf(address(this))
            );
        }
        uint256 toBal = IERC20(request.toToken).balanceOf(address(this));
        if (toBal > 0) {
            SafeERC20.safeTransfer(
                IERC20(request.toToken),
                to,
                IERC20(request.toToken).balanceOf(address(this))
            );
        }

        return result;
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override returns (uint256) {
        require(
            msg.sender == dexRouter,
            "Only dexRouter can call this function"
        );
        return _pmmSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override returns (uint256) {
        require(
            msg.sender == dexRouter,
            "Only dexRouter can call this function"
        );
        return _pmmSwap(to, pool, moreInfo);
    }
}
