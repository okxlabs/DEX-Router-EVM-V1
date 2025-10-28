// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface INexttoken {

    function getSwapTokenIndex(
        bytes32 key, 
        address tokenAddress
    ) external returns (uint8);

    function swap(
        bytes32 key,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function getSwapTokenBalance(
        bytes32 key, 
        uint8 index
    ) external view returns (uint256);

    function getSwapAPrecise(bytes32 key) external view returns (uint256);

    function getSwapA(bytes32 key) external view returns (uint256);

    function getSwapLPToken(bytes32 key) external view returns (address);

    //function getSwapStorage(bytes32 key) external view returns (SwapUtils.Swap memory);

    //function getSwapToken(bytes32 key, uint8 index) external view returns (IERC20);

    function getSwapVirtualPrice(bytes32 key) external view returns (uint256);

    function calculateSwap(
        bytes32 key,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateSwapTokenAmount(
        bytes32 key,
        uint256[] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calculateRemoveSwapLiquidity(bytes32 key, uint256 amount) external view returns (uint256[] memory);

    function calculateRemoveSwapLiquidityOneToken(
        bytes32 key,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    function getSwapAdminBalance(bytes32 key, uint256 index) external view returns (uint256);
}