// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IEtherFiLP.sol";
import "../libraries/SafeERC20.sol";

contract EtherFiEethAdapter is IAdapter {
    using SafeERC20 for IERC20;

    address public immutable WETH;
    address public immutable ETHERFI_LP;

    constructor(address _weth, address _etherfiLp) {
        WETH = _weth;
        ETHERFI_LP = _etherfiLp;
    }

    // WETH -> eETH (unwrap WETH then deposit to get eETH)
    function sellBase(
        address to,
        address pool,
        bytes memory
    ) external override {
        uint256 amount = IERC20(WETH).balanceOf(address(this));
        
        // Unwrap WETH to ETH
        IWETH(WETH).withdraw(amount);
        
        // Deposit ETH to get eETH shares
        IEtherFiLP(ETHERFI_LP).deposit{value: amount}();

        // Transfer eETH to recipient if not this contract
        if (to != address(this)) {
            address eETH = IEtherFiLP(ETHERFI_LP).eETH();
            SafeERC20.safeTransfer(
                IERC20(eETH),
                to,
                IERC20(eETH).balanceOf(address(this))
            );
        }
    }

    // Not implemented as this adapter only supports one-way conversion
    function sellQuote(
        address to,
        address pool,
        bytes memory
    ) external override {
        revert("eETH withdraw not supported");
    }

    receive() external payable {}
}
