// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/INativeRfqPoolV3.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

contract NativePmmAdapterV3 is IAdapter {
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal constant ORIGIN_PAYER =
        0x3ca20afc2ccc0000000000000000000000000000000000000000000000000000;
    address public immutable WETH;
    constructor(address _weth) {
        WETH = _weth;
    }

    function _NativePmmSwap(
        address to,
        address pool,
        bytes memory moreInfo,
        uint256 payerOrigin
    ) internal {
        address _payerOrigin;
        if ((payerOrigin & ORIGIN_PAYER) == ORIGIN_PAYER) {
            _payerOrigin = address(uint160(uint256(payerOrigin)));
        }
        INativeRfqPoolV3.RFQTQuote memory quote = abi.decode(
            moreInfo,
            (INativeRfqPoolV3.RFQTQuote)
        );
        uint256 actualAmountIn;
        uint256 value;
        if (quote.sellerToken == address(0)) {
            value = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(value);
            actualAmountIn = value;
        } else {
            actualAmountIn = IERC20(quote.sellerToken).balanceOf(address(this));
            SafeERC20.safeApprove(
                IERC20(quote.sellerToken),
                pool,
                actualAmountIn
            );
            value = 0;
        }

        INativeRfqPoolV3 rfqPool = INativeRfqPoolV3(payable(pool));
        // Comment: if actual amount deviation >= 10%, only 9% is executed;
        // the rest is refunded to the user.
        if (actualAmountIn >= (quote.sellerTokenAmount * 110) / 100) {
            actualAmountIn = (quote.sellerTokenAmount * 109) / 100;
        }
        try rfqPool.tradeRFQT{value: value}(quote, actualAmountIn, 0) {
            // New version succeeded
        } catch {
            // Fallback to legacy version
            rfqPool.tradeRFQT{value: value}(quote);
        }

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
        // FIX: refund token left to payerOrigin
        if (quote.sellerToken != address(0) && _payerOrigin != address(0)) {
            SafeERC20.safeTransfer(
                IERC20(quote.sellerToken),
                _payerOrigin,
                IERC20(quote.sellerToken).balanceOf(address(this))
            );
        } else if (
            quote.sellerToken == address(0) && _payerOrigin != address(0)
        ) {
            // refund ETH
            (bool success, ) = payable(_payerOrigin).call{
                value: address(this).balance
            }("");
            require(success, "refund ETH failed");
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        uint256 payerOrigin;
        assembly {
            let size := calldatasize()
            payerOrigin := calldataload(sub(size, 32))
        }
        _NativePmmSwap(to, pool, moreInfo, payerOrigin);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        uint256 payerOrigin;
        assembly {
            let size := calldatasize()
            payerOrigin := calldataload(sub(size, 32))
        }
        _NativePmmSwap(to, pool, moreInfo, payerOrigin);
    }
    receive() external payable {}
}
