// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/UniAdapterForRebaseToken.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract UniAdapterForRebaseTokenTest is Test {
    DexRouter dexRouter = DexRouter(payable(0xf332761c673b59B21fF6dfa8adA44d78c12dEF09));
    address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
    address amy = vm.rememberKey(1);
    address pool = 0xA885a1E7511CF6B572d949b1E60ac0A8449F3b18;
    address USDPlus = 0xe80772Eaf6e2E18B651F160Bc9158b2A5caFCA65; //token0
    address USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; //token1

    UniAdapterForRebaseToken adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ARB_RPC_URL"), 278441579);
        adapter = new UniAdapterForRebaseToken();
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_swapUSDPlusToUSDCe() public{
        address user = 0xa38C97D901166cDA369652D66807C8fd700e6e99;
        vm.startPrank(user);

        console2.log("USD+ balance before", IERC20(USDPlus).balanceOf(user));
        console2.log("USDCe balance before", IERC20(USDCe).balanceOf(user));
        
        uint256 amount = 1 * 10 ** 6;

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDPlus)));
        swapInfo.baseRequest.toToken = USDCe;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);

        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(
                abi.encodePacked(uint8(0x00), uint88(10000), address(pool))
            )
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "";
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDPlus)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("USD+ balance after", IERC20(USDPlus).balanceOf(user));
        console2.log("USDCe balance after", IERC20(USDCe).balanceOf(user));
    }

    function test_swapUSDCeToUSDPlus() public{
        vm.startPrank(amy);
        deal(USDCe, amy, 0.09 * 10 ** 6);
        
        console2.log("USD+ balance before", IERC20(USDPlus).balanceOf(address(amy)));
        console2.log("USDCe balance before", IERC20(USDCe).balanceOf(address(amy)));
        uint256 amount = 0.09 * 10 ** 6;
        SafeERC20.safeApprove(IERC20(USDCe), tokenApprove, amount);

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDCe)));
        swapInfo.baseRequest.toToken = USDPlus;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(
                abi.encodePacked(uint8(0x80), uint88(10000), address(pool))
            )
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "";
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDCe)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("USD+ balance after", IERC20(USDPlus).balanceOf(address(amy)));
        console2.log("USDCe balance after", IERC20(USDCe).balanceOf(address(amy)));
    }
}
