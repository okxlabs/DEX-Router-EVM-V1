// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IBancorNetwork.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

contract BancorAdapter is IAdapter {
    using SafeMath for uint;

    address constant BANCOR_ADDRESS = 0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function _bancorTrade(address to, address pool, bytes memory moreInfo) internal {
        IBancorNetwork bancorNetwork = IBancorNetwork(BANCOR_ADDRESS);
        (address sourceToken, address targetToken) = abi.decode(moreInfo, (address, address));
        address[] memory path = bancorNetwork.conversionPath(
            sourceToken,
            targetToken
        );
        // only support 1 Hop router
        require(path.length == 3, "BancorAdapter: MultiHop Route");

        // handle eth for special
        uint256 sellAmount = 0;
        uint256 sendValue = 0;
        if(sourceToken == ETH_ADDRESS) {
            sellAmount = IWETH(WETH_ADDRESS).balanceOf(address(this));
            IWETH(WETH_ADDRESS).withdraw(sellAmount);
            sendValue = sellAmount;
        } else{
            sellAmount = IERC20(sourceToken).balanceOf(address(this));
            // approve
            IERC20(sourceToken).approve(BANCOR_ADDRESS, sellAmount);
        }

        uint256 minReturn = bancorNetwork.rateByPath(
            path,
            sellAmount
        );

        // trade
        uint256 returnAmount = bancorNetwork.convertByPath{ value: sendValue }(
            path,
            sellAmount,
            minReturn,
            address(0),
            address(0),
            0
        );
        if(to != address(this)) {
            SafeERC20.safeTransfer(IERC20(targetToken), to, IERC20(targetToken).balanceOf(address(this)));
        }

    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _bancorTrade(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _bancorTrade(to, pool, moreInfo);
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}