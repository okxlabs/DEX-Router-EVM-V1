// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IAdapter} from "../interfaces/IAdapter.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IDODOV1.sol";

contract DODOV1Adapter is IAdapter, OwnableUpgradeable {

    address public immutable _DODO_SELL_HELPER_;

    constructor(address dodoSellHelper) {
        _DODO_SELL_HELPER_ = dodoSellHelper;
    }

    function sellBase(address to, address pool, bytes memory) external override {
        address curBase = IDODOV1(pool)._BASE_TOKEN_();
        uint256 curAmountIn = IERC20(curBase).balanceOf(address(this));  

        SafeERC20.safeApprove(IERC20(curBase), pool, curAmountIn);
        IDODOV1(pool).sellBaseToken(curAmountIn, 0, "");

        if(to != address(this)) {
            address curQuote = IDODOV1(pool)._QUOTE_TOKEN_();
            SafeERC20.safeTransfer(IERC20(curQuote), to, IERC20(curQuote).balanceOf(address(this)));
        }
    }

    function sellQuote(address to, address pool, bytes memory) external override {
        address curQuote = IDODOV1(pool)._QUOTE_TOKEN_();
        uint256 maxPayQuote = IERC20(curQuote).balanceOf(address(this));
        uint256 canBuyBaseAmount = IDODOSellHelper(_DODO_SELL_HELPER_).querySellQuoteToken(
            pool,
            maxPayQuote
        );

        SafeERC20.safeApprove(IERC20(curQuote), pool, maxPayQuote);
        IDODOV1(pool).buyBaseToken(canBuyBaseAmount, maxPayQuote, "");
        SafeERC20.safeApprove(IERC20(curQuote), pool, 0);

        if(to != address(this)) {
            address curBase = IDODOV1(pool)._BASE_TOKEN_();
            SafeERC20.safeTransfer(IERC20(curBase), to, canBuyBaseAmount);
        }
    }
    
    // QuerySellQuoteToken may cause 0～15 wei token left
    // To withdraw the left tokens
    // Design a withdrawLeftToken function to withdraw tokens

    function withdrawLeftToken(address pool) external onlyOwner {
        address curQuote = IDODOV1(pool)._QUOTE_TOKEN_();
        uint256 curAmountLeft = IERC20(curQuote).balanceOf(address(this));
        if (curAmountLeft > 0) {
            SafeERC20.safeTransfer(IERC20(curQuote), msg.sender, curAmountLeft);
        }
    }


}
