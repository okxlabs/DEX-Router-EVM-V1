// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAaveLendingPool.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

// only for ETH
contract AaveV2Adapter is IAdapter {

    address public immutable AAVE_LENDINGPOOL;

    constructor (
        address aaveLendingPool
    ) {
        AAVE_LENDINGPOOL = aaveLendingPool;
    }
        
    function _aaveV2Swap(
        address to,
        address ,
        bytes memory moreInfo
    ) internal {
        (address tokenIn, address tokenOut, bool tokenToAtoken) = abi.decode(moreInfo, (address, address, bool));
        //if tokenToAtoken is true, depositing token into pool to get atoken
        if (tokenToAtoken) {
            uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
            SafeERC20.safeApprove(
                IERC20(tokenIn),
                AAVE_LENDINGPOOL,
                amountIn
            );
            IAaveLendingPool(AAVE_LENDINGPOOL).deposit(tokenIn, amountIn, to, 0);
        } else {
            uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
            SafeERC20.safeApprove(
                IERC20(tokenIn),
                AAVE_LENDINGPOOL,
                amountIn
            );
            IAaveLendingPool(AAVE_LENDINGPOOL).withdraw(tokenOut, amountIn, to);
        } 
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _aaveV2Swap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _aaveV2Swap(to, pool, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}