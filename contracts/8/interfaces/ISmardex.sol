/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISmardexPair {
    
    /**
     * @notice get the token0 address
     * @return address of the token0
     */
    function token0() external view returns (address);

    /**
     * @notice get the token1 address
     * @return address of the token1
     */
    function token1() external view returns (address);

    /**
     * @notice Swaps tokens. Sends to the defined address the amount of token0 and token1 defined in parameters.
     * Tokens to trade should be already sent in the contract.
     * Swap function will check if the resulted balance is correct with current reserves and reserves fictive.
     * Should be called from a contract that makes safety checks like the SmardexRouter
     * @param _to address who will receive tokens
     * @param _zeroForOne token0 to token1
     * @param _amountSpecified amount of token wanted
     * @param _data used for flash swap, data.length must be 0 for regular swap
     */
    function swap(
        address _to,
        bool _zeroForOne,
        int256 _amountSpecified,
        bytes calldata _data
    ) external returns (int256 amount0_, int256 amount1_);    
}

interface ISmardexSwapCallback {
    /**
     * @notice callback data for swap
     * @param _amount0Delta amount of token0 for the swap (negative is incoming, positive is required to pay to pair)
     * @param _amount1Delta amount of token1 for the swap (negative is incoming, positive is required to pay to pair)
     * @param _data for Router path and payer for the swap (see router for details)
     */
    function smardexSwapCallback(int256 _amount0Delta, int256 _amount1Delta, bytes calldata _data) external;
}