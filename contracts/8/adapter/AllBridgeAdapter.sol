// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAllBridge.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

// The AllBridge Vault just support usdc & usdt.
contract AllBridgeAdapter is IAdapter {
    address immutable router;
    uint256 constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    constructor(address _router) {
        router = _router;
    }

    function _allBridgeSwap(address to, address, bytes memory data) internal {
        (bytes32 fromToken, bytes32 toToken) = abi.decode(data, (bytes32, bytes32));

        uint256 amountIn = IERC20(address(uint160(ADDRESS_MASK & uint256(fromToken)))).balanceOf(address(this));

        SafeERC20.safeApprove(IERC20(address(uint160(ADDRESS_MASK & uint256(fromToken)))), router, amountIn);

        IAllBridge(router).swap(amountIn, fromToken, toToken, to, 1);
    }

    function sellBase(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _allBridgeSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo)
        external
        override
    {
        _allBridgeSwap(to, pool, moreInfo);
    }

}