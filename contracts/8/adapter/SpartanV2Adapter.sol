// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/ISpartanV2Router.sol";

contract SpartanV2Adapter is IAdapter {
    
    address immutable router;

    constructor(
        address _router
    ) {
        router = _router;
    }

    //actually pool of no use, be compatible with Adapter template
    // SPARTA --> toToken
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (address fromToken, address toToken) = abi.decode(
            moreInfo,
            (address, address)
        );

        uint256 inputAmount = IERC20(fromToken).balanceOf(address(this));
        //Approve
        SafeERC20.safeApprove(
            IERC20(fromToken),
            address(router),
            inputAmount
        );

        //Swap
        ISpartanV2Router(router).buyTo(inputAmount, toToken, to, 0);

    }

    // fromToken --> SPARTA
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (address fromToken, address toToken) = abi.decode(
            moreInfo,
            (address, address)
        );

        uint256 inputAmount = IERC20(fromToken).balanceOf(address(this));
        //Approve
        SafeERC20.safeApprove(
            IERC20(fromToken),
            address(router),
            inputAmount
        );

        //Swap
        ISpartanV2Router(router).sellTo(inputAmount, fromToken, to, 0, false);

    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }

}