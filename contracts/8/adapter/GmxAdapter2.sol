// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IGmxVault.sol";
import "../libraries/SafeERC20.sol";

contract GmxAdapter2 is IAdapter {

    function _gmxSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address sourceToken, address targetToken) = abi.decode(
            moreInfo,
            (address, address)
        );
        // in case of multiple jumps inside GMX, we can not directly set the to address as the vault. because, the vault will 'SYNC' inside the transferOut func
        // so we need to set the to address as the adapter itself, then the adapter transfer token into vault. and after that, we call swap func
        SafeERC20.safeTransfer(IERC20(sourceToken), pool, IERC20(sourceToken).balanceOf(address(this)));
        IGmxVault(pool).swap(sourceToken, targetToken, to);
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _gmxSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _gmxSwap(to, pool, moreInfo);
    }

}
