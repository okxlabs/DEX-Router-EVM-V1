// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ISyncSwap.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract SyncSwapAdapter is IAdapter {

    address constant VAULT = 0x7160570BB153Edd0Ea1775EC2b2Ac9b65F1aB61B;

    // Withdraw with mode.
    // 0 = DEFAULT
    // 1 = UNWRAPPED
    // 2 = WRAPPED
    enum WithDrawModel {
        DEFAULT,
        UNWRAPPED,
        WRAPPED
    }

    function _synapseSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address fromToken) = abi.decode(moreInfo, (address));

        // token has transfer to the pool,
        // and now, the vault need to deposit.
        IVault(VAULT).deposit(fromToken, pool);

        // and swap
        bytes memory swapCalldata = abi.encode(fromToken, to, WithDrawModel.WRAPPED);
        ISyncSwap(pool).swap(
            swapCalldata,
            msg.sender,
            address(0),
            ""
        );
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _synapseSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _synapseSwap(to, pool, moreInfo);
    }
}