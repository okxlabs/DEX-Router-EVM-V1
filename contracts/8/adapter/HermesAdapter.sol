// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IAdapter.sol";
import "../interfaces/ISolidly.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";


contract HermesAdapter is IAdapter {
    IWETH WETH = IWETH(payable(0x75cb093E4D61d2A2e65D8e0BBb01DE8d89b53481));
    address ETH = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;

    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory
    ) external override {
        address baseToken = IPair(pool).token0();
        if (baseToken == ETH) {
            uint amount = WETH.balanceOf(address(this));
            WETH.withdraw(amount);
            IERC20(ETH).transfer(pool, amount);
        } else {
            SafeERC20.safeTransfer(IERC20(baseToken), pool, IERC20(baseToken).balanceOf(address(this)));
        }

        (uint256 _reserve0, uint256 _reserve1,) = IPair(pool).getReserves();
        require(
            _reserve0 > 0 && _reserve1 > 0,
            "Solidly: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0 = IERC20(baseToken).balanceOf(pool);
        uint256 sellBaseAmount = balance0 - _reserve0;
        uint256 receiveQuoteAmount = IPair(pool).getAmountOut(sellBaseAmount, baseToken);

        IPair(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory
    ) external override {
        address quoteToken = IPair(pool).token1();
        if (quoteToken == ETH) {
            uint amount = WETH.balanceOf(address(this));
            WETH.withdraw(amount);
            IERC20(ETH).transfer(pool, amount);
        } else {
            SafeERC20.safeTransfer(IERC20(quoteToken), pool, IERC20(quoteToken).balanceOf(address(this)));
        }
        (uint256 _reserve0, uint256 _reserve1,) = IPair(pool).getReserves();

        require(
            _reserve0 > 0 && _reserve1 > 0,
            "Solidly: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance1 = IERC20(quoteToken).balanceOf(pool);
        uint256 sellQuoteAmount = balance1 - _reserve1;
        uint256 receiveBaseAmount = IPair(pool).getAmountOut(sellQuoteAmount, quoteToken);

        IPair(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }

    receive() external payable{}

}