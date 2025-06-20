// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAspectaKeyPool.sol";
import "../interfaces/IWETH.sol";


contract AspectaAdapter is IAdapter {
    address constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WNATIVETOKEN;

    event Received(address sender, uint256 amount);
    // To record swap info for cases that the OrderRecord event is invalid.
    // direction: true for sellBase(buy key), false for sellQuote(sell key)
    event OrderRecord(bool direction, address fromToken, address toToken, uint256 fromAmount, uint256 toAmount);

    constructor(address payable wNativeToken) {
        WNATIVETOKEN = wNativeToken;
    }

    // fromToken == WNativeToken, toToken == Key
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint256 amount) = abi.decode(moreInfo, (uint256));
        // Withdraw all wnativeToken to nativeToken
        IWETH(WNATIVETOKEN).withdraw(IWETH(WNATIVETOKEN).balanceOf(address(this)));
        uint256 fromAmount = address(this).balance;
        // buyByRouter will increase the key balance of `to` address and send the surplus nativeToken to `to` address,
        // and will revert if the nativeToken is insufficient
        IAspectaKeyPool(pool).buyByRouter{value: address(this).balance}(amount, to);
        emit OrderRecord(true, NATIVE_ADDRESS, pool, fromAmount, amount);
    }

    // fromToken == Key, toToken == NativeToken and the nativeToken is send to tx.origin directly
    function sellQuote(
        address, // to
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint256 amount, uint256 minPrice, uint256 fee, address feeRecipient) = abi.decode(moreInfo, (uint256, uint256, uint256, address));
        uint256 toAmountBefore = address(tx.origin).balance;
        // sellByRouter will decrease the key balance of tx.origin and send the nativeToken to tx.origin
        IAspectaKeyPool(pool).sellByRouter(amount, minPrice, fee, feeRecipient);
        emit OrderRecord(false, pool, NATIVE_ADDRESS, amount, address(tx.origin).balance - toAmountBefore);
    }

    receive() external payable {
       emit Received(msg.sender, msg.value);
   }
}