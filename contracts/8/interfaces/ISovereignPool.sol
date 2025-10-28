// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISovereignPool {
    struct SovereignPoolSwapContextData {
        bytes externalContext;
        bytes verifierContext;
        bytes swapCallbackContext;
        bytes swapFeeModuleContext;
    }

    struct SovereignPoolSwapParams {
        bool isSwapCallback;
        bool isZeroToOne;
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 deadline;
        address recipient;
        address swapTokenOut;
        SovereignPoolSwapContextData swapContext;
    }

    function token0() external view returns (address);

    function token1() external view returns (address);

    function swap(
        SovereignPoolSwapParams calldata _swapParams
    ) external returns (uint256, uint256);
}
