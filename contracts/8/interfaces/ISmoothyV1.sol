pragma solidity 0.8.17;

import "./IERC20.sol";

interface ISmoothyV1 {
    function swap(
        uint256 bTokenIdxIn,
        uint256 bTokenIdxOut,
        uint256 bTokenInAmount,
        uint256 bTokenOutMin
    ) external;

    function swapAll(
        uint256 inOutFlag,
        uint256 lpTokenMintedMinOrBurnedMax,
        uint256 maxFee,
        uint256[] calldata amounts
    ) external;
}
