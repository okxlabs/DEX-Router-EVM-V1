// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITime {
    function Buy(address usd, uint256 amount) external returns (bool);
    function Sell(address usd, uint256 time) external returns (bool);
}
