// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IKokonutSwapPool {
    event TokenExchange(
        address indexed buyer,
        uint256 soldId,
        uint256 tokensSold,
        uint256 boughtId,
        uint256 tokensBought,
        uint256 fee
    );
    event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256 tokenSupply);
    event FlashLoan(address indexed borrower, uint256[] amounts, uint256[] fees);

    function N_COINS() external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function token() external view returns (address);

    function coins(uint256 i) external view returns (address);

    function getPrice(uint256 i, uint256 j) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function A() external view returns (uint256);

    function fee() external view returns (uint256);

    function adminFee() external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy,
        bytes calldata data
    ) external returns (uint256, uint256);

    function flashLoanFee() external view returns (uint256);

    function removeLiquidity(uint256 amount, uint256[] calldata minAmounts) external returns (uint256[] memory);

    function getDy(uint256 i, uint256 j, uint256 dx) external view returns (uint256, uint256);

    function calcWithdraw(uint256 amount) external view returns (uint256[] memory);

    function flashLoan(IKokonutSwapFlashCallback borrower, uint256[] calldata amounts, bytes calldata data) external;

    function withdrawLostToken(address token, uint256 amount, address to) external;
}





interface IKokonutSwapFlashCallback {
    function onFlashLoan(
        address initiator,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}