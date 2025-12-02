/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ISmoothyV1 {
    /*
     * @dev Swap a token to another.
     * @param bTokenIdIn - the id of the token to be deposited
     * @param bTokenIdOut - the id of the token to be withdrawn
     * @param bTokenInAmount - the amount (unnormalized) of the token to be deposited
     * @param bTokenOutMin - the mininum amount (unnormalized) token that is expected to be withdrawn
     */
    function swap(
        uint256 bTokenIdxIn,
        uint256 bTokenIdxOut,
        uint256 bTokenInAmount,
        uint256 bTokenOutMin
    ) external;

    /*
     * @dev Swap tokens given all token amounts
     * The amounts are pre-fee amounts, and the user will provide max fee expected.
     * Currently, do not support penalty.
     * @param inOutFlag - 0 means deposit, and 1 means withdraw with highest bit indicating mint/burn lp token
     * @param lpTokenMintedMinOrBurnedMax - amount of lp token to be minted/burnt
     * @param maxFee - maximum percentage of fee will be collected for withdrawal
     * @param amounts - list of unnormalized amounts of each token
     */
    function swapAll(
        uint256 inOutFlag,
        uint256 lpTokenMintedMinOrBurnedMax,
        uint256 maxFee,
        uint256[] calldata amounts
    ) external;
}
