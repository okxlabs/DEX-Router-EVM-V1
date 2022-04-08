// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapterWithResult.sol";
import "../interfaces/IMarketMaker.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract PMMAdapter is IAdapterWithResult {

    address public marketMaker;
    address public tokenApprove;

    constructor(address _marketMaker, address _tokenApprove) {
        marketMaker = _marketMaker;
        tokenApprove = _tokenApprove;
    }

    function _pmmSwap(address to, address pool, bytes memory moreInfo) internal returns (uint256) {
        pool;  // unused
        (   
            uint256 actualRequestAmount,
            IMarketMaker.PMMSwapRequest memory request,
            bytes memory signature  
        ) = abi.decode(moreInfo, (uint256, IMarketMaker.PMMSwapRequest, bytes));

        // uint256 sellAmount = IERC20(request.fromToken).balanceOf(address(this));

        // // approve
        // SafeERC20.safeApprove(IERC20(request.fromToken),  tokenApprove, sellAmount);

        // uint256 pathIndex;
        // address payer;
        // address fromToken;
        // address toToken;
        // uint256 fromTokenAmountMax;
        // uint256 toTokenAmountMax;
        // uint256 salt;
        // uint256 deadLine;
        // bool    isPushOrder;
        // IMarketMaker.PMMSwapRequest memory request;
        // request.pathIndex = pathIndex;
        // request.payer = address(this);
        // request.fromToken = fromToken;
        // request.toToken = toToken;
        // request.fromTokenAmountMax = fromTokenAmountMax;
        // request.toTokenAmountMax = toTokenAmountMax;
        // request.salt = salt;
        // request.deadLine = dealline;
        // request.isPushOrder = isPushOrder;

        return IMarketMaker(marketMaker).swap(
            to, actualRequestAmount, request, signature
        );

        // if(to != address(this)) {
        //     SafeERC20.safeTransfer(IERC20(request.toToken), to, IERC20(request.toToken).balanceOf(address(this)));
        // }
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override returns (uint256) {
        pool;   // unused
        return _pmmSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override returns (uint256){
        pool;   // unused
        return _pmmSwap(to, pool, moreInfo);
    }

    // receive() external payable {
    //     require(msg.value > 0, "receive error");
    // }
}