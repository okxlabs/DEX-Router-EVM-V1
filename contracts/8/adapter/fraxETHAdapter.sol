// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IFraxEth.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

// only for ETH
contract fraxETHAdapter is IAdapter {

    address public immutable WETH;
    address public immutable FRXETHMINTER;
    address public immutable SFRXETH;
    address public immutable FRXETH;

    enum SWAPTYPE {
        ETH_TO_FRXETH,
        FRXETH_TO_SFRXETH,
        SFRXETH_TO_FRXETH,
        ETH_SFRXETH
    }

    constructor (
        address weth,
        address frxETHMinter,
        address sfrxETH,
        address frxETH
    ) {
        WETH = weth;
        FRXETHMINTER = frxETHMinter;
        SFRXETH = sfrxETH;
        FRXETH = frxETH;
    }
        
    // 1. eth->frxeth
    // 2. frxeth->sfrxeth （deposit)
    // 3. sfrxeth -> frxeth (withdraw)
    // 4. eth -> sfrxeth
    // TODO: use pool address to store SWAPTYPE
    function _fraxSwap(
        address to,
        address ,
        bytes memory moreInfo
    ) internal {
        (SWAPTYPE swapType) = abi.decode(moreInfo, (SWAPTYPE));
        if (swapType == SWAPTYPE.ETH_TO_FRXETH) {
            _eth_to_fraxeth(to);
        } else if (swapType == SWAPTYPE.FRXETH_TO_SFRXETH) {
            _fraxeth_to_sfrxeth(to);
        } else if (swapType == SWAPTYPE.SFRXETH_TO_FRXETH) {
            _sfraxeth_to_frxeth(to);
        } else if (swapType == SWAPTYPE.ETH_SFRXETH) {
            _eth_to_sfraxeth(to);
        } else {
        }
    }

    function _eth_to_fraxeth(address to) internal {
        uint256 amountIn = IERC20(WETH).balanceOf(address(this));        
        IWETH(WETH).withdraw(amountIn);
        IfrxETHMinter(FRXETHMINTER).submitAndGive{value: amountIn}(to);
    }

    function _fraxeth_to_sfrxeth(address to) internal {
        uint256 amountIn = IERC20(FRXETH).balanceOf(address(this));
        SafeERC20.safeApprove(IERC20(FRXETH), SFRXETH, amountIn);
        IsfrxETH(SFRXETH).deposit(amountIn, to);
    }

    function _sfraxeth_to_frxeth(address to) internal {
        uint256 amountIn = IERC20(SFRXETH).balanceOf(address(this));
        IsfrxETH(SFRXETH).redeem(amountIn, to, address(this));
    }

    function _eth_to_sfraxeth(address to) internal {
        uint256 amountIn = IERC20(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amountIn);
        IfrxETHMinter(FRXETHMINTER).submitAndDeposit{value: amountIn}(to);
    }


    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _fraxSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _fraxSwap(to, pool, moreInfo);
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}