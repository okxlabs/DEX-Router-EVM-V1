// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AspectaKeyPool Interface
 * @dev Interface for the AspectaKeyPool contract
 */
interface IAspectaKeyPool {
    function buyByRouter(
        uint256 amount,
        address recipient
    ) external payable;

    function sellByRouter(
        uint256 amount,
        uint256 minPrice
    ) external;

    function getBuyPrice(
        uint256 amount
    ) external view returns (uint256);

    function getSellPrice(
        uint256 amount
    ) external view returns (uint256);

    function getPurchaseAmountByPayment(
        uint256 payment
    ) external view returns (uint256, uint256);

    function balanceOf(
        address user
    ) external view returns (uint256);

    function getProtocolFeePercentage() external view returns (uint256);

}
