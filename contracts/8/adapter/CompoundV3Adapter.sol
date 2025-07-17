// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IAdapter.sol";
import "../interfaces/ICTokenV3.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract CompoundV3Adapter is IAdapter {
    function _compound(address to, address, bytes memory moreInfo) internal {
        (address fromToken, address toToken, bool isMint) = abi.decode(
            moreInfo,
            (address, address, bool)
        );
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        if (isMint) {
            SafeERC20.safeApprove(IERC20(fromToken), toToken, amount);
            ICTokenV3(toToken).supplyTo(to, fromToken, amount);
            return;
        } else {
            ICTokenV3(fromToken).withdrawTo(to, toToken, amount);
            return;
        }
    }
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _compound(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _compound(to, pool, moreInfo);
    }
}
