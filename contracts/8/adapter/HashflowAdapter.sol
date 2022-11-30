// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IAdapter.sol";
import "../interfaces/IHashflow.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";

contract HashflowAdapter is IAdapter {

    address public immutable HASHFLOWROUTER ;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WETH_ADDRESS;

    constructor (address _HashflowRouter, address _weth) {
        HASHFLOWROUTER = _HashflowRouter;
        WETH_ADDRESS = _weth;
    }

    function _hashflowSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {        
        ( address fromToken, address toToken, IQuote memory Quote) = abi.decode(moreInfo, (address, address, IQuote));
        require( Quote.pool == pool, "error pool" );
        
        uint256 sellAmount = 0;
        if (fromToken == ETH_ADDRESS) {
            sellAmount = IWETH(WETH_ADDRESS).balanceOf(address(this));
            IWETH(WETH_ADDRESS).withdraw(sellAmount);
            IHashflow(HASHFLOWROUTER).tradeSingleHop{value: sellAmount}(Quote);
        } else {
            sellAmount = IERC20(fromToken).balanceOf(address(this));
            SafeERC20.safeApprove(IERC20(fromToken), HASHFLOWROUTER,  sellAmount );
            IHashflow(HASHFLOWROUTER).tradeSingleHop(Quote);
        }

        // approve 0
        SafeERC20.safeApprove(
            IERC20(fromToken == ETH_ADDRESS ? WETH_ADDRESS : fromToken),
            pool,
            0
        );

        if (to != address(this)) {
            if (toToken == ETH_ADDRESS) {
                IWETH(WETH_ADDRESS).deposit{value: address(this).balance}();
                toToken = WETH_ADDRESS;
            }
            SafeERC20.safeTransfer(
                IERC20(toToken),
                to,
                IERC20(toToken).balanceOf(address(this))
            );
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _hashflowSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _hashflowSwap(to, pool, moreInfo);
    }


    function withdrawLeftToken(address curQuote) public {
        uint256 curAmountLeft = IERC20(curQuote).balanceOf(address(this));
        if (curAmountLeft > 0) {
            SafeERC20.safeTransfer(IERC20(curQuote), msg.sender, curAmountLeft);
        }
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}