// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract UniversalAdapterTestUtils is Test {
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    address bob = vm.rememberKey(1);

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function genSwapInfo(
        address _adapter,
        address _fromToken,
        address _toToken,
        address _poolAddress,
        uint256 _amount
    ) internal view returns (SwapInfo memory swapInfo) {
        // orderId is implicitly 0 by default as SwapInfo is memory swapInfo;
        // If a specific orderId is needed, it should be set explicitly.
        // swapInfo.orderId = 0; 

        swapInfo.baseRequest.fromToken = uint256(uint160(_fromToken));
        swapInfo.baseRequest.toToken = _toToken;
        swapInfo.baseRequest.fromTokenAmount = _amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = _amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = _adapter;
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = _adapter; 
        swapInfo.batches[0][0].rawData = new uint[](1);
        // The constant 10000 was used in the original rawData encoding. 
        // If this value (e.g., fee tier or other parameter) needs to be dynamic, 
        // it should be passed as a parameter as well.
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), _poolAddress)));
        swapInfo.batches[0][0].extraData = new bytes[](1); 
        swapInfo.batches[0][0].extraData[0] = abi.encode(0, abi.encode(_fromToken, _toToken, 0));
        swapInfo.batches[0][0].fromToken = uint256(uint160(_fromToken));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        
        return swapInfo;
    }
}
