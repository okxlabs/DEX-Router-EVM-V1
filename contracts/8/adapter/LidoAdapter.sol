
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/ILidoVault.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract LidoAdapter is IAdapter {

    address immutable weth;

    constructor(address wethAddr) {
        weth = wethAddr;
    }

    address constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address constant stMatic = 0x9ee91F9f426fA633d227f7a9b000E28b9dfd8599;
    address constant Matic = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
    address constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    address constant ZERO_ADDRESS = address(0);

    uint256 private constant D_FLAG_MASK = 0x80000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant T_FLAG_MASK = 0x0f000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MIN_AMOUNT_MASK =  0x000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    function _lidoSwap(
        address to,
        address vault,
        bytes memory moreInfo
    ) internal {
        (uint256 minAmount) = abi.decode(moreInfo, (uint256));

        address underlyingToken;
        uint256 underlyingAmount;

        bool direction;
        assembly {
            direction := and(minAmount, D_FLAG_MASK)
        }
        uint8 flag;
        assembly {
            flag := shr(240, and(minAmount, T_FLAG_MASK))
        }
        assembly {
            minAmount := and(minAmount, MIN_AMOUNT_MASK)
        }

        if (direction) {
            // only support wstETH -> stETH
            require(vault == wstETH, "Wrong Token");

            uint256 shares =  ILidoVault(vault).balanceOf(address(this));

            // 2. pay back shares, get underlyingToken
            ILidoVault(vault).unwrap(shares);

            // 3. get underlying amount
            underlyingAmount = ILidoVault(vault).balanceOf(address(this));
            require(shares >= minAmount, "not enough");
            if (to != address(this)) {
                SafeERC20.safeTransfer(
                    IERC20(vault),
                    to,
                    underlyingAmount
                );
            }
        } else {
            // weth -> wstETH/stETH: flag = 0
            // matic -> stMatic: flag
            // stETH -> wstETH : flag = 1
            if ((vault == stETH || vault == wstETH) && flag != 1) {
                // deposit weth
                underlyingAmount = IWETH(weth).balanceOf(address(this));
                // Convert WETH to ETH
                if(underlyingAmount > 0) {
                    IWETH(weth).withdraw(underlyingAmount);
                }
                underlyingAmount = address(this).balance;
                (bool success,) = payable(vault).call{value: underlyingAmount}("");
                require(success, "transfer native token error");
            } else if (vault == stMatic) {
                underlyingToken = Matic;
                underlyingAmount = IERC20(underlyingToken).balanceOf(address(this));
                SafeERC20.safeApprove(IERC20(underlyingToken), vault, underlyingAmount);
                ILidoVaultMatic(vault).submit(underlyingAmount, ZERO_ADDRESS);
            } else if (vault == wstETH && flag == 1) {
                underlyingToken = stETH;
                underlyingAmount = IERC20(underlyingToken).balanceOf(address(this));
                SafeERC20.safeApprove(IERC20(underlyingToken), vault, underlyingAmount);
                ILidoVault(vault).wrap(underlyingAmount);
            } else {
                revert("param error");
            }

            uint256 shares = IERC20(vault).balanceOf(address(this));
            require(shares >= minAmount, "not enough");
            if (to != address(this)) {
                SafeERC20.safeTransfer(
                    IERC20(vault),
                    to,
                    shares
                );
            }
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _lidoSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _lidoSwap(to, pool, moreInfo);
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
    }
}