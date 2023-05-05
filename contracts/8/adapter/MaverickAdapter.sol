// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";

import "../interfaces/IMaverick.sol";
import "../interfaces/IERC20.sol";

import "../libraries/SafeERC20.sol";
import "../libraries/TickMath.sol";
import "../interfaces/IWETH.sol";

/// @title UniV3Adapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract MaverickAdapter is IAdapter {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant ADDR_SIZE = 20;
    IWETH public immutable WETH;
    IFactory public immutable factory;

    struct SwapCallbackData {
        bytes path;
        address payer;
        bool exactOutput;
    }

    constructor(address _factory, address payable _WETH) {
        factory = IFactory(_factory);
        WETH = IWETH(_WETH);
    }

    function _maverickSwap(address to, address, bytes memory _data) internal {
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (IERC20 fromToken, IERC20 toToken, IPool pool) = decodeFirstPool(data.path);

        if (address(fromToken) == ETH_ADDRESS) {
            fromToken = IERC20(address(WETH));
        }

        uint256 sellAmount = fromToken.balanceOf(address(this));
        bool zeroForOne = fromToken < toToken;
        // @param sqrtPriceLimit limiting sqrt price of the swap.  A value of 0
        //indicates no limit.  Limit is only engaged for exactOutput=false.  If the
        //limit is reached only part of the input amount will be swapped and the
        //callback will only require that amount of the swap to be paid.

        //tokenAIn bool indicating whether tokenA is the input => equals zeroForOne
        // zeroForOne is true, then fromToken < toToken, fromToken is TokenA, tokenAIn is true
        // zeroForOne is fale, then fromToken > toToken, fromToken is not TokenA, tokenAIn is false
        pool.swap(to, sellAmount, zeroForOne, false, 0, _data);
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _maverickSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _maverickSwap(to, pool, moreInfo);
    }

    // for uniV3 callback
    function swapCallback(uint256 amountToPay, uint256 amountOut, bytes calldata _data) external {
        require(amountToPay > 0 && amountOut > 0, "In or Out Amount is Zero");
        require(IFactory(factory).isFactoryPool(IPool(msg.sender)), "Must call from a Factory Pool");

        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (IERC20 fromToken,, IPool pool) = decodeFirstPool(data.path);

        require(msg.sender == address(pool), "msgSender doesnt match address pool");

        if (address(fromToken) == ETH_ADDRESS) {
            fromToken = IERC20(address(WETH));
        }

        pay(fromToken, data.payer, msg.sender, amountToPay);
    }

    function decodeFirstPool(bytes memory path) internal pure returns (IERC20 fromToken, IERC20 toToken, IPool pool) {
        require(path.length >= 20 * 3, "must be greater than 60 bytes");
        assembly {
            let firstPtr := add(path, 32)
            fromToken := shr(mul(12, 8), mload(firstPtr))
            pool := shr(mul(12, 8), mload(add(firstPtr, 20)))
            toToken := shr(mul(12, 8), mload(add(firstPtr, 40)))
        }
    }

    function pay(IERC20 token, address payer, address recipient, uint256 value) internal {
        if (IWETH(address(token)) == WETH && address(this).balance >= value) {
            WETH.deposit{value: value}();
            WETH.transfer(recipient, value);
        } else if (payer == address(this)) {
            SafeERC20.safeTransfer(token, recipient, value);
        } else {
            SafeERC20.safeTransferFrom(token, payer, recipient, value);
        }
    }
}
