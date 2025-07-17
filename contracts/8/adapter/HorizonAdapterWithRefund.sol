// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IHorizon.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

contract HorizonAdapterWithRefund is IAdapter, ISwapCallback {
    /// @dev specific flag for refund logic, "0x3ca20afc" is flexible and also used for commission, "ccc" mean refund
    uint256 constant ORIGIN_PAYER = 0x3ca20afc2ccc0000000000000000000000000000000000000000000000000000;
    uint256 constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WETH;

    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    constructor(address payable _weth) {
        WETH = _weth;
    }

    function _swap(address to, address pool, uint160 limitSqrtP, bytes memory data, uint256 payerOrigin) internal {
        (address fromToken, address toToken,) = abi.decode(data, (address, address, uint24));

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroForOne = fromToken < toToken;

        IHorizon(pool).swap(
            to,
            int256(sellAmount),
            zeroForOne,
            limitSqrtP == 0 ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1) : limitSqrtP,
            data
        );
        /// @notice Refund logic: if there is leftover fromToken, refund to payerOrigin
        address _payerOrigin;
        if ((payerOrigin & ORIGIN_PAYER) == ORIGIN_PAYER) {
            _payerOrigin = address(uint160(uint256(payerOrigin) & ADDRESS_MASK));
        }
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        if (amount > 0 && _payerOrigin != address(0)) {
            SafeERC20.safeTransfer(IERC20(fromToken), _payerOrigin, amount);
        }
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        (uint160 limitSqrtP, bytes memory data) = abi.decode(moreInfo, (uint160, bytes));
        _swap(to, pool, limitSqrtP, data, _getPayerOrigin());
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        (uint160 limitSqrtP, bytes memory data) = abi.decode(moreInfo, (uint160, bytes));
        _swap(to, pool, limitSqrtP, data, _getPayerOrigin());
    }

    // like uniV3 callback, KyberElastic callback
    function swapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external {
        require(amount0Delta > 0 || amount1Delta > 0, "not ok"); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut,) = abi.decode(_data, (address, address, uint24));
        address tokenA = tokenIn;
        address tokenB = tokenOut;
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }

        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0 ? (tokenIn < tokenOut, uint256(amount0Delta)) : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) {
            pay(tokenIn, address(this), msg.sender, amountToPay);
        } else {
            tokenIn = tokenOut;
            pay(tokenIn, address(this), msg.sender, amountToPay);
        }
    }

    function pay(address token, address payer, address recipient, uint256 value) internal {
        if (token == WETH && address(this).balance >= value) {
            // pay with WETH9
            IWETH(WETH).deposit{value: value}(); // wrap only what is needed to pay
            IWETH(WETH).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            revert("should not reach here");
        }
    }

    function _getPayerOrigin() internal pure returns (uint256 payerOrigin) {
        assembly {
            // Get the total size of the calldata
            let size := calldatasize()
            // Load the last 32 bytes of the calldata, which is assumed to contain the payer origin
            // Assumption: The calldata is structured such that the payer origin is always at the end
            payerOrigin := calldataload(sub(size, 32))
        }
    }
}
