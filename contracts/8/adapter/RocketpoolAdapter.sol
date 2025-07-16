// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IRocketPool.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

// only for ETH
contract RocketpoolAdapter is IAdapter {

    address public immutable RETH;
    address public immutable WETH;
    address public immutable DEPOSITPOOL;

    constructor (
        address rETH,
        address depositpool,
        address wETH
    ) {
        RETH = rETH;
        WETH = wETH;
        DEPOSITPOOL = depositpool;
    }
        
    // true：deposit weth-eth-reth
    // false：withdraw reth-eth-weth
    function _rocketSwap(
        address to,
        address ,
        bytes memory moreInfo
    ) internal {
        (bool direction) = abi.decode(moreInfo, (bool));
        if (direction) {
            uint256 amountIn = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amountIn);
            IRocketDepositPool(DEPOSITPOOL).deposit{value: address(this).balance}();
            if (to != address(this)) {
                SafeERC20.safeTransfer(
                    IERC20(RETH),
                    to,
                    IERC20(RETH).balanceOf(address(this))
                );
            }
        } else {
            uint256 amountIn = IERC20(RETH).balanceOf(address(this)); 
            IRETH(RETH).burn(amountIn);
            IWETH(WETH).deposit{value: address(this).balance}();
            if (to != address(this)) {
                SafeERC20.safeTransfer(
                    IERC20(WETH),
                    to,
                    IERC20(WETH).balanceOf(address(this))
                );
            }
        } 
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _rocketSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _rocketSwap(to, pool, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}