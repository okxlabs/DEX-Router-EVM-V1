// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IUniswapV1Pair.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

contract UniswapV1Adapter is IAdapter {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable FACTORY_ADDRESS =
        0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor() {}
    // from token=ETH
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        uint amount = IWETH(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amount);
        IUniswapV1(pool).ethToTokenTransferInput{value: amount}(
            1,
            block.timestamp,
            to
        );
    }
    // from token=token
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        address token = IUniswapV1(pool).tokenAddress();
        uint amount = IERC20(token).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(token), pool, amount);
        uint amountOut = IUniswapV1(pool).tokenToEthSwapInput(
            amount,
            1,
            block.timestamp
        );
        IWETH(WETH).deposit{value: amountOut}();
        IWETH(WETH).transfer(to, amountOut);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}
