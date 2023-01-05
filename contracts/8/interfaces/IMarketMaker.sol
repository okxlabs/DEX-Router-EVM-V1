/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libraries/PMMLib.sol";

interface IMarketMaker {
    function PMMV2SwapFromSmartRouter(
        uint256 actualAmountRequest,
        address fromTokenpayer,
        PMMLib.PMMSwapRequest calldata pmmRequest
    ) external returns (uint256);

    function dexRouterSwap(
        uint256 actualAmountRequest,
        address fromTokenpayer,
        PMMLib.PMMSwapRequest calldata pmmRequest
    ) external returns (uint256);

}
