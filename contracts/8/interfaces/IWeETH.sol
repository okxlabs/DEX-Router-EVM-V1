// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IWeETH {
    /// @notice The eETH token contract
    function eETH() external view returns (address);

    /// @notice Wraps eEth
    /// @param _eETHAmount the amount of eEth to wrap
    /// @return returns the amount of weEth the user receives
    function wrap(uint256 _eETHAmount) external returns (uint256);

    /// @notice Unwraps weETH
    /// @param _weETHAmount the amount of weETH to unwrap
    /// @return returns the amount of eEth the user receives
    function unwrap(uint256 _weETHAmount) external returns (uint256);

    /// @notice Fetches the amount of weEth respective to the amount of eEth sent in
    /// @param _eETHAmount amount sent in
    /// @return The total number of shares for the specified amount
    function getWeETHByeETH(uint256 _eETHAmount) external view returns (uint256);

    /// @notice Fetches the amount of eEth respective to the amount of weEth sent in
    /// @param _weETHAmount amount sent in
    /// @return The total amount for the number of shares sent in
    function getEETHByWeETH(uint256 _weETHAmount) external view returns (uint256);

    /// @notice Gets the current exchange rate between weETH and eETH
    /// @return Amount of weETH for 1 eETH
    function getRate() external view returns (uint256);

    /// @notice Gets the implementation address for the upgradeable contract
    function getImplementation() external view returns (address);
}
