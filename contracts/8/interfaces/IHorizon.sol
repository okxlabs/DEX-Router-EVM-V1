// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IHorizon {
    function swap(address recipient, int256 swapQty, bool isToken0, uint160 limitSqrtP, bytes calldata data)
        external
        returns (int256 qty0, int256 qty1);
}

interface ISwapCallback {
    function swapCallback(int256 deltaQty0, int256 deltaQty1, bytes calldata data) external;
}

interface IFactory {
    function poolInitHash() external view returns (bytes32);
}

interface IPool {
    function swapFeeUnits() external view returns (uint24);
}
