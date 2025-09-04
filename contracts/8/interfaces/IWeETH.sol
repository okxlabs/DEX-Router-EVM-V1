// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWeETH {
    function eETH() external view returns (address);

    function wrap(uint256 _eETHAmount) external returns (uint256);

    function unwrap(uint256 _weETHAmount) external returns (uint256);

    function getWeETHByeETH(uint256 _eETHAmount) external view returns (uint256);
    
    function getEETHByWeETH(uint256 _weETHAmount) external view returns (uint256);

    function getRate() external view returns (uint256);

    function getImplementation() external view returns (address);
}
