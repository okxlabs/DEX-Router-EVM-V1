// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/test.sol";
import "@dex/adapter/SparkPsmAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

//virtuals internal trading
contract SparkPsmTest is Test {

    address bob = vm.rememberKey(1);

    function setUp() public {

    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    // modifier tokenBalance(address _user) {
    //     console2.log("USDC balance before", IERC20(USDC).balanceOf(address(_user)));
    //     console2.log("USDT balance before", IERC20(USDT).balanceOf(address(_user)));
    //     _;
    //     console2.log("USDC balance after", IERC20(USDC).balanceOf(address(_user)));
    //     console2.log("USDT balance after", IERC20(USDT).balanceOf(address(_user)));
    // }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_sparkPsm_USDS_to_USDC() public user(bob) {
        
        DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
        address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

        address USDS_base = 0x820C137fa70C8691f0e44Dc420a5e53c168921Dc;
        address sUSDS_base = 0x5875eEE11Cf8398102FdAd704C9E96607675467a;
        address USDC_base = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        address PSM3 = 0x1601843c5E9bC251A3272907010AFa41Fa18347E;

        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 24972889);
        //https://basescan.org/tx/0x5d4f43be4db58cab580eb5e95217307c485fab53d3bbbe525e750b2c7a0c53cb
        
        SparkPsmAdapter adapter = new SparkPsmAdapter(PSM3);
        
        deal(USDS_base, bob, 0.1 * 10 ** 18);
        IERC20(USDS_base).approve(tokenApprove, 0.1 * 10 ** 18);

        uint256 amount = IERC20(USDS_base).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDS_base)));
        swapInfo.baseRequest.toToken = USDC_base;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDS_base, USDC_base);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDS_base)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("USDS_base balance before", IERC20(USDS_base).balanceOf(address(bob)));
        console2.log("USDC_base balance before", IERC20(USDC_base).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("USDS_base balance after", IERC20(USDS_base).balanceOf(address(bob)));
        console2.log("USDC_base balance after", IERC20(USDC_base).balanceOf(address(bob)));
    }

    function test_sparkPsm_USDC_to_USDS() public user(bob) {
        
        DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
        address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

        address USDS_base = 0x820C137fa70C8691f0e44Dc420a5e53c168921Dc;
        address USDC_base = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        address PSM3 = 0x1601843c5E9bC251A3272907010AFa41Fa18347E;

        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 24972889);
        
        SparkPsmAdapter adapter = new SparkPsmAdapter(PSM3);
        
        deal(USDC_base, bob, 0.1 * 10 ** 6);
        IERC20(USDC_base).approve(tokenApprove, 0.1 * 10 ** 6);

        uint256 amount = IERC20(USDC_base).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC_base)));
        swapInfo.baseRequest.toToken = USDS_base;
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
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDC_base, USDS_base);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC_base)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("USDC_base balance before", IERC20(USDC_base).balanceOf(address(bob)));
        console2.log("USDS_base balance before", IERC20(USDS_base).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("USDC_base balance after", IERC20(USDC_base).balanceOf(address(bob)));
        console2.log("USDS_base balance after", IERC20(USDS_base).balanceOf(address(bob)));
    }

    function test_sparkPsm_USDS_to_sUSDS() public user(bob) {
        
        DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
        address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

        address USDS_base = 0x820C137fa70C8691f0e44Dc420a5e53c168921Dc;
        address sUSDS_base = 0x5875eEE11Cf8398102FdAd704C9E96607675467a;
        address PSM3 = 0x1601843c5E9bC251A3272907010AFa41Fa18347E;

        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 24972889);
        
        SparkPsmAdapter adapter = new SparkPsmAdapter(PSM3);
        
        deal(USDS_base, bob, 0.1 * 10 ** 18);
        IERC20(USDS_base).approve(tokenApprove, 0.1 * 10 ** 18);

        uint256 amount = IERC20(USDS_base).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDS_base)));
        swapInfo.baseRequest.toToken = sUSDS_base;
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
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDS_base, sUSDS_base);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDS_base)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("USDS_base balance before", IERC20(USDS_base).balanceOf(address(bob)));
        console2.log("sUSDS_base balance before", IERC20(sUSDS_base).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("USDS_base balance after", IERC20(USDS_base).balanceOf(address(bob)));
        console2.log("sUSDS_base balance after", IERC20(sUSDS_base).balanceOf(address(bob)));
    }

    


}
