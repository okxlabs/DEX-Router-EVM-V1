// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ITridentPool.sol";
import "../interfaces/ITridentBento.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract TridentAdapter is IAdapter {

    address public immutable BENTO;
    
    constructor(address _bento) {
        BENTO = _bento;
    }
    function _tridentSwap(
        address to,
        address pool,        
        bytes memory moreInfo
    ) internal {
        address tokenIn = abi.decode(moreInfo, (address));
        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(tokenIn),
            BENTO,
            amountIn
        );
        ITridentBento(BENTO).deposit(IERC20(tokenIn), address(this), address(this), amountIn, 0);
        uint256 shares = ITridentBento(BENTO).balanceOf(IERC20(tokenIn), address(this));
        ITridentBento(BENTO).transfer(IERC20(tokenIn),address(this), pool, shares);
        bytes memory swapdata = abi.encode(tokenIn,to,true);
        ITridentPool(pool).swap(swapdata);

    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _tridentSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _tridentSwap(to, pool, moreInfo);
    }

}
