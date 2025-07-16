// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISynthetixWrapper.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

// only for ETH
contract WrappedSynthetixAdapter is IAdapter {

        
    function _synthetixWrapper(
        address to,
        address ,
        bytes memory moreInfo
    ) internal {
        (address tokenIn, address tokenOut, address wrapper) = abi.decode(moreInfo, (address, address, address));
        //if tokenTostoken is true, wrapping token as synth token
        address underlyingAssets = ISynthetixWrapper(wrapper).token();
        bool tokenTostoken = tokenIn == underlyingAssets ? true : false;
        if (tokenTostoken) {
            //require(ISynthetixWrapper(wrapper).token() == tokenIn,"synthetixwrapper doesn't match the token");
            uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
            SafeERC20.safeApprove(
                IERC20(tokenIn),
                wrapper,
                amountIn
            );
            ISynthetixWrapper(wrapper).mint(amountIn);
            SafeERC20.safeTransfer(
                IERC20(tokenOut),
                to,
                IERC20(tokenOut).balanceOf(address(this))
            );
        } else {
            //require(ISynthetixWrapper(wrapper).token() == tokenOut,"synthetixwrapper doesn't match the token");
            uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
            SafeERC20.safeApprove(
                IERC20(tokenIn),
                wrapper,
                amountIn
            );
            ISynthetixWrapper(wrapper).burn(amountIn);
            SafeERC20.safeTransfer(
                IERC20(tokenOut),
                to,
                IERC20(tokenOut).balanceOf(address(this))
            );
        } 
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _synthetixWrapper(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _synthetixWrapper(to, pool, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}