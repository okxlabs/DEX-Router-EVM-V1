// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IFushionX.sol";
import "../interfaces/IERC20.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";
/// @title UniV3Adapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details

contract FushionXAdapter is IAdapter {
    address public immutable WMNT;
    address public immutable deployer;
    bytes32 public constant POOL_INIT_CODE_HASH = 0x1bce652aaa6528355d7a339037433a20cd28410e3967635ba8d2ddb037440dbf;

    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    constructor(address payable _WMNT, address _deployer) {
        WMNT = _WMNT;
        deployer = _deployer;
    }

    function _fushionXSwap(address to, address pool, uint160 sqrtX96, bytes memory data) internal {
        (address fromToken, address toToken,) = abi.decode(data, (address, address, uint24));

        uint256 sellAmount = IERC20(fromToken).balanceOf(address(this));
        bool zeroForOne = fromToken < toToken;

        IFushionX(pool).swap(
            to,
            zeroForOne,
            int256(sellAmount),
            sqrtX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1) : sqrtX96,
            data
        );
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        (uint160 sqrtX96, bytes memory data) = abi.decode(moreInfo, (uint160, bytes));
        _fushionXSwap(to, pool, sqrtX96, data);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        (uint160 sqrtX96, bytes memory data) = abi.decode(moreInfo, (uint160, bytes));
        _fushionXSwap(to, pool, sqrtX96, data);
    }

    // for uniV3 callback
    function fusionXV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external {
        require(amount0Delta > 0 || amount1Delta > 0, "calculate wrong"); // swaps entirely within 0-liquidity regions are not supported
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
                            hex"ff", deployer, keccak256(abi.encode(tokenA, tokenB, fee)), POOL_INIT_CODE_HASH
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
            pay(tokenOut, address(this), msg.sender, amountToPay);
        }
    }

    function pay(address token, address payer, address recipient, uint256 value) internal {
        if (token == WMNT && address(this).balance >= value) {
            // pay with WMNT9
            IWETH(WMNT).deposit{value: value}(); // wrap only what is needed to pay
            IWETH(WMNT).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            revert("can not reach here");
        }
    }
}
