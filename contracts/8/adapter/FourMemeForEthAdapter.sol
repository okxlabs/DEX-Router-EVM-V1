// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/IFourMeme.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

/// @title FourMemeForEthAdapter
/// @notice This adapter is only used for selling meme tokens for BNB through TokenManagerHelper3,
/// and buyMeme is not supported. To keep the same moreInfo encoding as `FourMemeAdapter`, the same
/// struct `TradeInfo` is defined here.
contract FourMemeForEthAdapter is IAdapter {
    uint256 constant MINAMOUNT = 0;
    uint256 constant PLATFORM = 0;
    uint256 constant GWEI = 10 ** 9;
    address public immutable WNATIVE;
    address public immutable TOKENMANAGERHELPER3; // bsc

    struct TradeInfo {
        address fundAddress; // not used, just for compatibility
        address tokenAddress; // not used, just for compatibility
        bool buyMeme; // must be false, buyMeme is not supported
        uint256 sellMemeAmount;
        uint256 sellCommissionRate1;
        address sellCommissionReceiver1;
        uint256 sellCommissionRate2;
        address sellCommissionReceiver2;
        uint256 minReturnAmount;
    }

    // To record swap info for cases that the OrderRecord event is invalid.
    // direction: true for buy meme, false for sell meme
    event OrderRecord(bool direction, address fromToken, address toToken, uint256 fromAmount, uint256 toAmount);

    constructor (
        address Wnative,
        address TokenManagerHelper3
    ) {
        WNATIVE = Wnative;
        TOKENMANAGERHELPER3 = TokenManagerHelper3;
    }

    function _fourMemeTrading(
        address,
        bytes memory moreInfo
    ) private {
        uint256 amountIn;
        uint256 amountOut;
        TradeInfo memory tradeInfo = abi.decode(moreInfo, (TradeInfo));
        require(tradeInfo.buyMeme == false, "buyMeme is not supported");
        require(tradeInfo.fundAddress != WNATIVE, "only support ERC20/ERC20 pairs");
        require(tradeInfo.sellCommissionRate1 + tradeInfo.sellCommissionRate2 <= 300, "exceed commission rate cap");

        amountIn = tradeInfo.sellMemeAmount;
        if (amountIn % GWEI != 0) {
            amountIn = (amountIn / GWEI) * GWEI;
            require(amountIn > 0, "processed amountIn is 0");
        }

        amountOut = _getBalance(address(0), tx.origin);

        ITokenManagerHelper3(TOKENMANAGERHELPER3).sellForEth(PLATFORM, tradeInfo.tokenAddress, tx.origin, amountIn, MINAMOUNT, tradeInfo.sellCommissionRate1 + tradeInfo.sellCommissionRate2, address(this));
        uint256 amountTotal= _getBalance(tradeInfo.fundAddress, address(this));
        if (tradeInfo.sellCommissionReceiver1 != address(0)) {
            uint256 amount1 = amountTotal * tradeInfo.sellCommissionRate1 / (tradeInfo.sellCommissionRate1 + tradeInfo.sellCommissionRate2);
            _safeTransfer(tradeInfo.fundAddress, tradeInfo.sellCommissionReceiver1, amount1);
        }
        if (tradeInfo.sellCommissionReceiver2 != address(0)) {
            uint256 amount2 = amountTotal * tradeInfo.sellCommissionRate2 / (tradeInfo.sellCommissionRate1 + tradeInfo.sellCommissionRate2);
            _safeTransfer(tradeInfo.fundAddress, tradeInfo.sellCommissionReceiver2, amount2);
        }
        
        amountOut = _getBalance(address(0), tx.origin) - amountOut;
        require(amountOut >= tradeInfo.minReturnAmount, "Min return not reached");
        emit OrderRecord(false, tradeInfo.tokenAddress, WNATIVE, amountIn, amountOut);
    }

    function _getBalance(address token, address user) internal view returns (uint256) {
        if (token == address(0)) {
            return address(user).balance;
        } else {
            return IERC20(token).balanceOf(user);
        }
    }

    function _safeTransfer(address token, address receiver, uint256 amount) internal {
        if (token == address(0)) {
            (bool success, ) = payable(receiver).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(token), receiver, amount);
        }
    }

    function sellBase(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        _fourMemeTrading(to,moreInfo);
    }

    function sellQuote(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        _fourMemeTrading(to, moreInfo);
    }
}