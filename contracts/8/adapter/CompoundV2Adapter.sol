// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ICToken.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

contract CompoundAdapter is IAdapter {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WETH;

    constructor(address _weth) {
        WETH = _weth;
    }

    function _compound(address to, address, bytes memory moreInfo) internal {
        (address fromToken, address toToken, bool isMint) = abi.decode(moreInfo, (address, address, bool));

        if (isMint) {
            require(ICToken(toToken).isCToken(), "mint toToken must be cToken");
            _handleMint(to, fromToken, toToken);
            return;
        } else {
            require(ICToken(fromToken).isCToken(), "redeem fromToken must be cToken");
            _handleRedeem(to, fromToken, toToken);
            return;
        }
    }

    function _handleMint(address to, address fromToken, address toToken) internal {
        if (fromToken == ETH_ADDRESS) {
            uint256 amount = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amount);
            ICToken(toToken).mint{value: address(this).balance}();
        } else {
            uint256 amount = IERC20(fromToken).balanceOf(address(this));
            SafeERC20.safeApprove(IERC20(fromToken), toToken, amount);
            uint256 resMint = ICToken(toToken).mint(amount);
            require(resMint == 0, "mint failed");
        }
        if (to != address(this)) {
            uint256 amount = IERC20(toToken).balanceOf(address(this));
            SafeERC20.safeTransfer(IERC20(toToken), to, amount);
        }
    }

    function _handleRedeem(address to, address fromToken, address toToken) internal {
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        uint256 resRedeem = ICToken(fromToken).redeem(amount);
        require(resRedeem == 0, "redeem failed");
        if (toToken == ETH_ADDRESS) {
            IWETH(WETH).deposit{value: address(this).balance}();
            toToken = WETH;
        }
        if (to != address(this)) {
            uint256 amountTx = IERC20(toToken).balanceOf(address(this));
            SafeERC20.safeTransfer(IERC20(toToken), to, amountTx);
        }
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _compound(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _compound(to, pool, moreInfo);
    }

    receive() external payable {}
}
