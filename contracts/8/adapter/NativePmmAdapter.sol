// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/INativeRfqPool.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";
contract NativePmmAdapter is IAdapter {
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WETH;
    constructor(address _weth) {
        WETH = _weth;
    }

    function _NativePmmSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        INativeRfqPool.RFQTQuote memory quote = abi.decode(
            moreInfo,
            (INativeRfqPool.RFQTQuote)
        );
        uint256 value = quote.sellerToken == address(0)
            ? quote.effectiveSellerTokenAmount
            : 0;
        if (quote.sellerToken == address(0)) {
            IWETH(WETH).withdraw(value);
        } else {
            SafeERC20.safeApprove(
                IERC20(quote.sellerToken),
                pool,
                quote.effectiveSellerTokenAmount
            );
        }
        INativeRfqPool(pool).tradeRFQT{value: value}(quote);
        if (quote.buyerToken == address(0)) {
            IWETH(WETH).deposit{value: address(this).balance}();
            SafeERC20.safeTransfer(
                IERC20(WETH),
                to,
                IERC20(WETH).balanceOf(address(this))
            );
        } else {
            SafeERC20.safeTransfer(
                IERC20(quote.buyerToken),
                to,
                IERC20(quote.buyerToken).balanceOf(address(this))
            );
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _NativePmmSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _NativePmmSwap(to, pool, moreInfo);
    }
    receive() external payable {}
}
