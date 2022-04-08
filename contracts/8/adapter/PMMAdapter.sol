// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapterWithResult.sol";
import "../interfaces/IMarketMaker.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IApproveProxy.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract PMMAdapter is IAdapterWithResult {

    address public marketMaker;
    address public dexRouter;

    constructor(address _marketMaker, address _dexRouter){
        marketMaker = _marketMaker;
        dexRouter = _dexRouter;
    }

<<<<<<< HEAD
    function _pmmSwap(address to, address pool, bytes memory moreInfo) internal returns (uint256) {
        pool;  // unused
        (   
=======
    function _pmmSwap(address to, address /*pool*/, bytes memory moreInfo) internal returns (uint256) {
        (
>>>>>>> fdc490a45c578126f5ae6483fd22aed150da1975
            uint256 actualRequestAmount,
            IMarketMaker.PMMSwapRequest memory request,
            bytes memory signature  
        ) = abi.decode(moreInfo, (uint256, IMarketMaker.PMMSwapRequest, bytes));

        uint256 sellAmount = IERC20(request.fromToken).balanceOf(address(this));

        // approve
        address approveProxy = IMarketMaker(marketMaker).approveProxy();
        address tokenApprove = IApproveProxy(approveProxy).tokenApprove();
        SafeERC20.safeApprove(IERC20(request.fromToken),  tokenApprove, sellAmount);

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

        uint256 result = IMarketMaker(marketMaker).swap(
            to, actualRequestAmount, request, signature
        );

        if(to != address(this)) {
            SafeERC20.safeTransfer(IERC20(request.toToken), to, IERC20(request.toToken).balanceOf(address(this)));
        }

        return result;
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override returns (uint256) {
<<<<<<< HEAD
        pool;   // unused
        return _pmmSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override returns (uint256){
        pool;   // unused
=======
        require(msg.sender == dexRouter, 'Only dexRouter can call this function');
        return _pmmSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override returns (uint256) {
        require(msg.sender == dexRouter, 'Only dexRouter can call this function');
>>>>>>> fdc490a45c578126f5ae6483fd22aed150da1975
        return _pmmSwap(to, pool, moreInfo);
    }
}