pragma solidity ^0.8.0;

interface ISmardexPair {
    
    function token0() external view returns (address);

    function token1() external view returns (address);

    function swap(
        address _to,
        bool _zeroForOne,
        int256 _amountSpecified,
        bytes calldata _data
    ) external returns (int256 amount0_, int256 amount1_);    
}

interface ISmardexSwapCallback {
    function smardexSwapCallback(int256 _amount0Delta, int256 _amount1Delta, bytes calldata _data) external;
}
