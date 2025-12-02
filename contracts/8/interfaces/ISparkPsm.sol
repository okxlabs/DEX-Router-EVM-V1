/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

interface ISparkPsm {

    /**
     *  @dev    Returns the address of the rate provider, a contract that provides the conversion
     *          rate between sUSDS and the other two assets in the PSM (e.g., sUSDS to USD).
     *  @return The address of the rate provider.
     */
    function rateProvider() external view returns (address);

    /**
     *  @dev    Swaps a specified amount of assetIn for assetOut in the PSM. The amount swapped is
     *          converted based on the current value of the two assets used in the swap. This
     *          function will revert if there is not enough balance in the PSM to facilitate the
     *          swap. Both assets must be supported in the PSM in order to succeed.
     *  @param  assetIn      Address of the ERC-20 asset to swap in.
     *  @param  assetOut     Address of the ERC-20 asset to swap out.
     *  @param  amountIn     Amount of the asset to swap in.
     *  @param  minAmountOut Minimum amount of the asset to receive.
     *  @param  receiver     Address of the receiver of the swapped assets.
     *  @param  referralCode Referral code for the swap.
     *  @return amountOut    Resulting amount of the asset that will be received in the swap.
     */
    function swapExactIn(
        address assetIn,
        address assetOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        uint256 referralCode
    ) external returns (uint256 amountOut);

}
