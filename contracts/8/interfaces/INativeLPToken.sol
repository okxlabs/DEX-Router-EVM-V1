// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INativeLPToken {
    function sharesOf(address account) external returns (uint256 shares);

    function depositFor(address to, uint256 amount) external returns (uint256 sharesToMint);

    function redeemTo(uint256 sharesToBurn, address to) external returns (uint256 underlyingAmount);

    function underlying() external returns (address underlyingToken);

    function getSharesByUnderlying(uint256 underlyingAmount) external view returns (uint256);

    function getUnderlyingByShares(uint256 sharesAmount) external view returns (uint256);
}
