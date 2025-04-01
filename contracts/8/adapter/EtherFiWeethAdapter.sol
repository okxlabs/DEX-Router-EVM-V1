// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IWeETH.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

contract EtherFiWeethAdapter is IAdapter {

    address public immutable WEETH_ADDRESS;
    address public immutable EETH_ADDRESS;

    constructor(address _weeth) {
        WEETH_ADDRESS = _weeth;
        EETH_ADDRESS = IWeETH(_weeth).eETH();
    }

    // eETH -> weETH
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        uint256 amount = IERC20(EETH_ADDRESS).balanceOf(address(this));
        
        // Approve eETH to WeETH contract
        SafeERC20.safeApprove(IERC20(EETH_ADDRESS), WEETH_ADDRESS, amount);
        
        // Wrap eETH to weETH
        IWeETH(WEETH_ADDRESS).wrap(amount);

        // Transfer weETH to recipient if not this contract
        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(WEETH_ADDRESS),
                to,
                IERC20(WEETH_ADDRESS).balanceOf(address(this))
            );
        }
    }

    // weETH -> eETH
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        uint256 amount = IERC20(WEETH_ADDRESS).balanceOf(address(this));
        
        // Unwrap weETH to eETH
        IWeETH(WEETH_ADDRESS).unwrap(amount);

        // Transfer eETH to recipient if not this contract
        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(EETH_ADDRESS),
                to,
                IERC20(EETH_ADDRESS).balanceOf(address(this))
            );
        }
    }
} 