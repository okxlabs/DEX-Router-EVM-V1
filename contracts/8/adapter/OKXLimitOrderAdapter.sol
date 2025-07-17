// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IOKXLimitOrder.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

contract OKXLimitOrderAdapter is IAdapter {
    address public immutable OKXLimitOrderV2;
    address public immutable tokenApprove;
    IWETH public immutable WETH;

    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _limitOrderV2, address _tokenApprove, address _WETH) {
        OKXLimitOrderV2 = _limitOrderV2;
        tokenApprove = _tokenApprove;
        WETH = IWETH(_WETH);
    }

    function _limitOrderSwap(
        address to,
        address,
        bytes memory moreInfo
    ) internal {
        (Order memory order, bytes memory signature) = abi.decode(
            moreInfo,
            (Order, bytes)
        );

        address takerToken = order.takerToken;
        uint256 takingAmount;
        if (takerToken == ETH) {
            takingAmount = WETH.balanceOf(address(this));
        } else {
            takingAmount = IERC20(takerToken).balanceOf(address(this));
        }

        Trade memory trade = Trade({
            signature: signature,
            target: to,
            makingAmount: 0,
            takingAmount: takingAmount,
            minReturn: 0
        });

        if (takerToken == ETH) {
            WETH.withdraw(takingAmount); //WETH - > ETH
            IOKXLimitOrder(OKXLimitOrderV2).fillOrder{value: takingAmount}(
                order,
                trade
            );
        } else {
            SafeERC20.safeApprove(
                IERC20(takerToken),
                tokenApprove,
                takingAmount
            );
            IOKXLimitOrder(OKXLimitOrderV2).fillOrder(order, trade);
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _limitOrderSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _limitOrderSwap(to, pool, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}
