// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISynthetixWrapper.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

// only for ETH
contract SynthetixEtherWrapperAdapter is IAdapter {

    address constant ETHERWRAPPER_ADDRESS = 0xC1AAE9d18bBe386B102435a8632C8063d31e747C;
    address constant PROXYSETH_ADDRESS = 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb;
    address constant WETH9_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    function _synthetixEtherWrapper(
        address to,
        address ,
        bytes memory moreInfo
    ) internal {
        (bool tokenTostoken) = abi.decode(moreInfo, (bool));
        //if tokenTostoken is true, wrapping WETH as sETH

        if (tokenTostoken) {
            uint256 amountIn = IERC20(WETH9_ADDRESS).balanceOf(address(this));
            SafeERC20.safeApprove(
                IERC20(WETH9_ADDRESS),
                ETHERWRAPPER_ADDRESS,
                amountIn
            );
            ISynthetixEtherWrapper(ETHERWRAPPER_ADDRESS).mint(amountIn);
            SafeERC20.safeTransfer(
                IERC20(PROXYSETH_ADDRESS),
                to,
                IERC20(PROXYSETH_ADDRESS).balanceOf(address(this))
            );
        } else {
            uint256 amountIn = IERC20(PROXYSETH_ADDRESS).balanceOf(address(this));
            SafeERC20.safeApprove(
                IERC20(PROXYSETH_ADDRESS),
                ETHERWRAPPER_ADDRESS,
                amountIn
            );
            ISynthetixEtherWrapper(ETHERWRAPPER_ADDRESS).burn(amountIn);
            SafeERC20.safeTransfer(
                IERC20(WETH9_ADDRESS),
                to,
                IERC20(WETH9_ADDRESS).balanceOf(address(this))
            );
        } 
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _synthetixEtherWrapper(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _synthetixEtherWrapper(to, pool, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}