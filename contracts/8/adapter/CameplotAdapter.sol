// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IAdapter.sol";
import "../interfaces/ICameplot.sol";
import "../interfaces/IERC20.sol";

contract CameplotAdapter is IAdapter {

    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory 
    ) external override {
        address baseToken = ICameplotPair(pool).token0();
        (uint112 _reserve0, uint112 _reserve1 ,,) = ICameplotPair(pool).getReserves();
        require(
            _reserve0 > 0 && _reserve1 > 0,
            "Cameplot: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0 = IERC20(baseToken).balanceOf(pool);
        uint256 sellBaseAmount = balance0 - uint256(_reserve0);
        uint256 receiveQuoteAmount = ICameplotPair(pool).getAmountOut(sellBaseAmount, baseToken);

        ICameplotPair(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory 
    ) external override {
        address quoteToken = ICameplotPair(pool).token1();
        (uint112 _reserve0, uint112 _reserve1 ,,) = ICameplotPair(pool).getReserves();
        
        require(
            _reserve0 > 0 && _reserve1 > 0,
            "Cameplot: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance1 = IERC20(quoteToken).balanceOf(pool);
        uint256 sellQuoteAmount = balance1 - uint256(_reserve1);
        uint256 receiveBaseAmount = ICameplotPair(pool).getAmountOut(sellQuoteAmount, quoteToken);
        
        ICameplotPair(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}