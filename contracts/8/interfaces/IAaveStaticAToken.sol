// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20.sol";

interface IAaveStaticAToken {

  function redeem(
    uint256 shares,
    address receiver,
    address owner,
    bool withdrawFromAave
  ) external returns (uint256, uint256);

  function deposit(
    uint256 assets,
    address receiver,
    uint16 referralCode,
    bool depositToAave
  ) external returns (uint256);

  function aToken() external view returns (IERC20);

  function asset() external view returns (address assetTokenAddress);
}
