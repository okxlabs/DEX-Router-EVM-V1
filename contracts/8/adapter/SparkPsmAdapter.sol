// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/ISparkPsm.sol";

//virtuals internal trading
contract SparkPsmAdapter is IAdapter {

    address public immutable PSM3;//base: 0x1601843c5E9bC251A3272907010AFa41Fa18347E

    constructor (
        address psm3
    ) {
        PSM3 = psm3;
    }

    function _sparkPsmTrading(
        address to,
        bytes memory moreInfo
    ) private {
        uint256 amountIn;
        (address fromTokenAddress, address toTokenAddress) = abi.decode(
            moreInfo,
            (address, address)
        );
        amountIn = IERC20(fromTokenAddress).balanceOf(address(this));
        IERC20(fromTokenAddress).approve(PSM3, amountIn);
        ISparkPsm(PSM3).swapExactIn(fromTokenAddress, toTokenAddress, amountIn, 0, to, 0);
    }

    function sellBase(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        _sparkPsmTrading(to,moreInfo);
    }

    function sellQuote(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        _sparkPsmTrading(to, moreInfo);
    }
}
