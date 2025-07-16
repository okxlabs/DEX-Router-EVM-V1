// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IPlatypus.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract PlatypusAdapter is IAdapter {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable WETH;

    constructor(address _WETH) {
        WETH = _WETH;
    }

    function _platypusSwap(address to, address pool, bytes memory moreInfo) internal {
        (address fromToken, address toToken, uint256 dealline) =
            abi.decode(moreInfo, (address, address, uint256));

        if (fromToken == ETH_ADDRESS) {
            fromToken = WETH;
        } else if (toToken == ETH_ADDRESS) {
            toToken = WETH;
        }

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        // approve
        SafeERC20.safeApprove(IERC20(fromToken), pool, sellAmount);

        IPlatypus(pool).swap(fromToken, toToken, sellAmount, 0, to, dealline);
    }

    function sellBase(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _platypusSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _platypusSwap(to, pool, moreInfo);
    }

    event Received(address msgSender, uint256 value);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}
