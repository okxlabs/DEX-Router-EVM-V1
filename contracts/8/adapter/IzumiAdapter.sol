// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IZumiSwap.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/IZumiPath.sol";
import "../interfaces/IWETH.sol";

contract IZumiAdapter is IAdapter, IiZiSwapCallback {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WETH;
    address public immutable FACTORY;

    using IZumiPath for bytes;

    constructor(address payable weth, address factory) {
        WETH = weth;
        FACTORY = factory;
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    function sellBase(address to, address izumiPool, bytes memory moreInfo) external override {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));
        uint24 fee = IiZiSwapPool(izumiPool).fee();

        // highPt for y2x, lowPt for x2y
        // here y2X is calling swapY2X or swapY2XDesireX
        // in swapY2XDesireX, if boundaryPt is 800001, means user wants to get enough X
        // in swapX2YDesireY, if boundaryPt is -800001, means user wants to get enough Y
        int24 boundaryPt = IiZiSwapPool(izumiPool).leftMostPt();

        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        IiZiSwapPool(izumiPool).swapX2Y(
            to,
            uint128(amount),
            boundaryPt,
            abi.encode(SwapCallbackData({path: abi.encodePacked(fromToken, fee, toToken), payer: address(this)}))
        );
    }

    // swapY2X
    function sellQuote(address to, address izumiPool, bytes memory moreInfo) external override {
        (address fromToken, address toToken) = abi.decode(moreInfo, (address, address));

        uint24 fee = IiZiSwapPool(izumiPool).fee();

        // highPt for y2x, lowPt for x2y
        // here y2X is calling swapY2X or swapY2XDesireX
        // in swapY2XDesireX, if boundaryPt is 800001, means user wants to get enough X
        // in swapX2YDesireY, if boundaryPt is -800001, means user wants to get enough Y
        int24 boundaryPt = IiZiSwapPool(izumiPool).rightMostPt();

        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        IiZiSwapPool(izumiPool).swapY2X(
            to,
            uint128(amount),
            boundaryPt,
            abi.encode(SwapCallbackData({path: abi.encodePacked(fromToken, fee, toToken), payer: address(this)}))
        );
    }

    function verify(address tokenX, address tokenY, uint24 fee) internal view {
        require(msg.sender == pool(tokenX, tokenY, fee), "sp");
    }

    function pool(address tokenX, address tokenY, uint24 fee) public view returns (address) {
        return IiZiSwapFactory(FACTORY).pool(tokenX, tokenY, fee);
    }

    function swapY2XCallback(uint256, uint256 y, bytes memory moreInfo) external override {
        SwapCallbackData memory dt = abi.decode(moreInfo, (SwapCallbackData));
        (address token0, address token1, uint24 fee) = dt.path.decodeFirstPool();

        verify(token0, token1, fee);
        if (token0 > token1) {
            // token0 is y, amount of token0 is input param
            // called from swapY2X(...)
            pay(token0, dt.payer, msg.sender, y);
        }
    }

    function swapX2YCallback(uint256 x, uint256, bytes memory moreInfo) external override {
        SwapCallbackData memory dt = abi.decode(moreInfo, (SwapCallbackData));
        (address token0, address token1, uint24 fee) = dt.path.decodeFirstPool();
        verify(token0, token1, fee);
        if (token0 < token1) {
            // token0 is x, amount of token0 is input param
            // called from swapX2Y(...)
            pay(token0, dt.payer, msg.sender, x);
        }
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(address token, address payer, address recipient, uint256 value) internal {
        if (token == WETH && address(this).balance >= value) {
            // pay with WETH9
            IWETH(WETH).deposit{value: value}(); // wrap only what is needed to pay
            IWETH(WETH).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            // pull payment
            SafeERC20.safeTransferFrom(IERC20(token), payer, recipient, value);
        }
    }
}
