// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAnyToken.sol";
import "../libraries/SafeERC20.sol";

contract MultichainAdapter is IAdapter {

    function _multichainSwap(
        address to,
        address pool
    ) internal {
        address underly_address = IAnyToken(pool).underlying();
        IAnyToken(pool).withdraw();

        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(underly_address),
                to,
                IERC20(underly_address).balanceOf(address(this))
            );
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory 
    ) external override {
        _multichainSwap(to, pool);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory 
    ) external override {
        _multichainSwap(to, pool);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}