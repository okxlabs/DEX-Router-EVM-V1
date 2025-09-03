pragma solidity ^0.8.0;
pragma abicoder v2;

interface IAaveLendingPool {

    function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
    ) external;
    function withdraw(
    address asset,
    uint256 amount,
    address to
    ) external returns (uint256);

}

interface IAaveV3Pool {
  function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
  
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}
