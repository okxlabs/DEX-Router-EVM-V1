/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
import "./IERC20.sol";

interface IOSwap {
    function token0() external returns (address);
    function token1() external returns (address);
    function owner() external returns (address);
    function swapExactTokensForTokens(IERC20, IERC20, uint256, uint256, address) external;
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256)
        external
        returns (uint256[] memory);
    function swapTokensForExactTokens(IERC20, IERC20, uint256, uint256, address) external;
    function swapTokensForExactTokens(uint256, uint256, address[] calldata, address, uint256)
        external
        returns (uint256[] memory);
    function setOwner(address newOwner) external;
    function setTraderates(uint256 _traderate0, uint256 _traderate1) external;
    function transferToken(address token, address to, uint256 amount) external;
}