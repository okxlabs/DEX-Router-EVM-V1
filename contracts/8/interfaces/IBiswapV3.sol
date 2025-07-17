// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBiswapV3 {
    function swapX2Y(
        address recipient,
        uint128 amount,
        int24 lowPt,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY, uint128 accFee);

    function swapY2X(
        address recipient,
        uint128 amount,
        int24 highPt,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY, uint128 accFee);
}
