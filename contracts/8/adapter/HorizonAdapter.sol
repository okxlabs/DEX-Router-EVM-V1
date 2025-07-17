// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IHorizon.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

contract HorizonAdapter is IAdapter, ISwapCallback {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WETH;
    address public immutable factory;
    bytes32 public immutable POOL_INIT_CODE_HASH;

    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    constructor(address payable _weth, address _factory) {
        WETH = _weth;
        factory = _factory;
        POOL_INIT_CODE_HASH = IFactory(_factory).poolInitHash();
    }

    function _swap(address to, address pool, uint160 limitSqrtP, bytes memory data) internal {
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
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        (uint160 limitSqrtP, bytes memory data) = abi.decode(moreInfo, (uint160, bytes));
        _swap(to, pool, limitSqrtP, data);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        (uint160 limitSqrtP, bytes memory data) = abi.decode(moreInfo, (uint160, bytes));
        _swap(to, pool, limitSqrtP, data);
    }

    // like uniV3 callback, KyberElastic callback
    function swapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external {
        require(amount0Delta > 0 || amount1Delta > 0, "not ok"); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut, uint24 fee) = abi.decode(_data, (address, address, uint24));
        address tokenA = tokenIn;
        address tokenB = tokenOut;
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        address computedAddr = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff", factory, keccak256(abi.encode(tokenA, tokenB, fee)), POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
        require(msg.sender == computedAddr, "wrong msgSender");

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
}
