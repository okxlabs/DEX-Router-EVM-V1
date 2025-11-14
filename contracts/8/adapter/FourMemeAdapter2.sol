// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/IFourMeme.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

contract FourMemeAdapter2 is IAdapter {

    uint256 constant MINAMOUNT = 0;
    uint256 constant PLATFORM = 0;
    uint256 constant GWEI = 10 ** 9;
    address public immutable WNATIVE;
    address public immutable TOKENMANAGER2;//0x5c952063c7fc8610FFDB798152D69F0B9550762b bsc

    struct TradeInfo {
        address fundAddress;
        address tokenAddress;
        bool buyMeme;
        uint256 sellMemeAmount;
        uint256 sellCommissionRate1;
        address sellCommissionReceiver1;
        uint256 sellCommissionRate2;
        address sellCommissionReceiver2;
        uint256 minReturnAmount;
    }

    event Received(address sender, uint256 amount);
    // To record swap info for cases that the OrderRecord event is invalid.
    // direction: true for buy meme, false for sell meme
    event OrderRecord(bool direction, address fromToken, address toToken, uint256 fromAmount, uint256 toAmount);

    constructor (
        address Wnative,
        address TokenManager2
    ) {
        WNATIVE = Wnative;
        TOKENMANAGER2 = TokenManager2;
    }

    function _fourMemeTrading(
        address to,
        bytes memory moreInfo
    ) private {
        uint256 amountIn;
        uint256 amountOut;
        TradeInfo memory tradeInfo = abi.decode(moreInfo, (TradeInfo));

        if (tradeInfo.buyMeme) {
            uint256 dust;
            amountOut = IERC20(tradeInfo.tokenAddress).balanceOf(to);
            if (tradeInfo.fundAddress == WNATIVE){
                amountIn = IERC20(WNATIVE).balanceOf(address(this));
                IWETH(WNATIVE).withdraw(amountIn);
                ITokenManager2(TOKENMANAGER2).buyTokenAMAP{value: amountIn}(tradeInfo.tokenAddress, to, amountIn, MINAMOUNT);
                dust = address(this).balance;
                if (dust > 0) {
                    (bool success, ) = to.call{value: dust}("");
                    require(success, "Transfer failed");
                }
            }else{
                amountIn = IERC20(tradeInfo.fundAddress).balanceOf(address(this));
                IERC20(tradeInfo.fundAddress).approve(TOKENMANAGER2, amountIn);
                ITokenManager2(TOKENMANAGER2).buyTokenAMAP(tradeInfo.tokenAddress, to, amountIn, MINAMOUNT);
                dust = IERC20(tradeInfo.fundAddress).balanceOf(address(this));
                if (dust > 0) {
                    IERC20(tradeInfo.fundAddress).transfer(to, dust);
                }
            }
            amountOut = IERC20(tradeInfo.tokenAddress).balanceOf(to) - amountOut;
            emit OrderRecord(true, tradeInfo.fundAddress, tradeInfo.tokenAddress, amountIn - dust, amountOut);
        } else {
            amountIn = tradeInfo.sellMemeAmount;
            if (amountIn % GWEI != 0) {
                amountIn = (amountIn / GWEI) * GWEI;
                require(amountIn > 0, "processed amountIn is 0");
            }
            address fundToken = tradeInfo.fundAddress == WNATIVE ? address(0) : tradeInfo.fundAddress;
            (bool success, ) = TOKENMANAGER2.call(abi.encodeWithSelector(0x930cc050, PLATFORM, tradeInfo.tokenAddress, tx.origin, address(this), amountIn, 1));
            require(success, "sellToken in fourmeme failed");
            amountOut = _getBalance(fundToken, address(this));
            _safeTransfer(fundToken, to, amountOut);
            
            emit OrderRecord(false, tradeInfo.tokenAddress, tradeInfo.fundAddress, amountIn, amountOut);
        }
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
            IWETH(WNATIVE).deposit{value: address(this).balance}();
            SafeERC20.safeTransfer(IERC20(WNATIVE), receiver, amount);
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

    receive() external payable {
       emit Received(msg.sender, msg.value);
   }
}
