// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ILevelPool.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";


contract LevelAdapter is IAdapter {


    function _levelSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (
            address tokenIn, 
            address tokenOut
        ) = abi.decode(moreInfo, (address, address));
        ILevelPool (pool).swap(tokenIn,tokenOut,0,to,"");
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _levelSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _levelSwap(to, pool, moreInfo);
    }

}

