// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IPlatypus.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";


contract PlatypusAdapter is IAdapter {
    // ============ Hard Coded ============
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // ============ Storage ============
    address public immutable WETH_ADDRESS;
    event Received(address, uint256);

    constructor(address _weth) {
        WETH_ADDRESS = _weth;
    }

    //--------------------------------
    //------- Users Functions --------
    //--------------------------------

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _platypusSwap(to, pool, moreInfo);
    }

       
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _platypusSwap(to, pool, moreInfo);
    }

    //--------------------------------
    //------ Internal Functions ------
    //--------------------------------
    function _platypusSwap(
        address to,
        address pool,
        bytes memory moreInfo
    ) internal {
        (address fromToken,address toToken)=abi.decode(moreInfo,(address,address));

        uint256 fromAmount = _balanceOf(fromToken,address(this));
        
        if (fromToken==ETH_ADDRESS){
            
            IPool(pool).swapFromETH{ value:fromAmount }(
                toToken,
                0,
                to,
                block.timestamp
            );

        }else if (toToken==ETH_ADDRESS) {
            // approve
            SafeERC20.safeApprove(IERC20(fromToken), pool, fromAmount);
            
            IPool(pool).swapToETH(
                fromToken,
                fromAmount,
                0,
                payable(to),
                block.timestamp
            );
            // approve 0
            SafeERC20.safeApprove(IERC20(fromToken), pool, 0);
        }else {
            // approve
            SafeERC20.safeApprove(IERC20(fromToken), pool, fromAmount); 
            
            IPool(pool).swap(
                fromToken,
                toToken,
                fromAmount,
                0,
                to,
                block.timestamp                
            );
            // approve 0
            SafeERC20.safeApprove(IERC20(fromToken), pool, 0);
        }
        
    }
    function _balanceOf(address token, address account) internal view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}