// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

import "./IERC20.sol";

interface IBalancerV3Vault {
    enum SwapKind {
        EXACT_IN,
        EXACT_OUT
    }
    
    struct VaultSwapParams {
        SwapKind kind;
        address pool;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountGivenRaw;
        uint256 limitRaw;
        bytes userData;
    }

    function unlock(bytes calldata data) external returns (bytes memory result);

    function settle(IERC20 token, uint256 amountHint) external returns (uint256 credit);

    function sendTo(IERC20 token, address to, uint256 amount) external;

    function swap(
        VaultSwapParams memory vaultSwapParams
    ) external returns (uint256 amountCalculatedRaw, uint256 amountInRaw, uint256 amountOutRaw);

}
