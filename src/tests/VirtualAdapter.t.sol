// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/test.sol";
import "@dex/adapter/VirtualsAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

//virtuals internal trading
contract VirtualTest is Test {

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

    function test_virtual_buy() public user(bob) {
        
        DexRouter dexRouter = DexRouter(payable(0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4));
        address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

        //swap virtualToken to memeToken
        address BONDING = 0xF66DeA7b3e897cD44A5a231c61B6B4423d613259;
        address virtualToken = 0x0b3e328455c4059EEb9e3f84b5543F74E24e7E1b;
        address memeToken = 0x8cCA61B50443f8997654bfc578fA1CbA3Eac2CDF;//name: fun AI COACH
        address FRouter = 0x8292B43aB73EfAC11FAF357419C38ACF448202C5;

        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 30508146);//old 24972889 buy 包含2个参数 ； new 30508146 buy 包含4个参数
        //https://basescan.org/tx/0x24dac92c6b5312aaf8205532417fddd3f66905b24d4bc509842b55638c468419
        //https://basescan.org/tx/0xacbe1db17b1cf1457c07a7f6e116ea823ab4dd9c399acd03e185a937d5f8de5e
        
        VirtualsAdapter adapter = new VirtualsAdapter(BONDING, virtualToken, FRouter);
        
        deal(virtualToken, bob, 10 * 10 ** 18);
        IERC20(virtualToken).approve(tokenApprove, 10 * 10 ** 18);

        uint256 amount = IERC20(virtualToken).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(virtualToken)));
        swapInfo.baseRequest.toToken = memeToken;
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
        swapInfo.batches[0][0].extraData[0] = abi.encode(memeToken, true, block.timestamp);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(virtualToken)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("virtualToken balance before", IERC20(virtualToken).balanceOf(address(bob)));
        console2.log("memeToken balance before", IERC20(memeToken).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("virtualToken balance after", IERC20(virtualToken).balanceOf(address(bob)));
        console2.log("memeToken balance after", IERC20(memeToken).balanceOf(address(bob)));
    }

    function test_virtual_sell() public user(bob) {

        DexRouter dexRouter = DexRouter(payable(0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4));
        address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

        //swap memeToken to virtualToken
        address BONDING = 0xF66DeA7b3e897cD44A5a231c61B6B4423d613259;
        address virtualToken = 0x0b3e328455c4059EEb9e3f84b5543F74E24e7E1b;
        address memeToken = 0x8cCA61B50443f8997654bfc578fA1CbA3Eac2CDF;//name: fun AI COACH
        address FRouter = 0x8292B43aB73EfAC11FAF357419C38ACF448202C5;

        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 30508146);//old 24972889 buy 包含2个参数 ； new 30508146 buy 包含4个参数
        //https://basescan.org/tx/0x24dac92c6b5312aaf8205532417fddd3f66905b24d4bc509842b55638c468419
        //https://basescan.org/tx/0xacbe1db17b1cf1457c07a7f6e116ea823ab4dd9c399acd03e185a937d5f8de5e
        
        VirtualsAdapter adapter = new VirtualsAdapter(BONDING, virtualToken, FRouter);
        
        deal(memeToken, bob, 10 * 10 ** 18);
        IERC20(memeToken).approve(tokenApprove, 10 * 10 ** 18);

        uint256 amount = IERC20(memeToken).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(memeToken)));
        swapInfo.baseRequest.toToken = virtualToken;
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
        swapInfo.batches[0][0].extraData[0] = abi.encode(memeToken, false, block.timestamp);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(memeToken)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("virtualToken balance before", IERC20(virtualToken).balanceOf(address(bob)));
        console2.log("memeToken balance before", IERC20(memeToken).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("virtualToken balance after", IERC20(virtualToken).balanceOf(address(bob)));
        console2.log("memeToken balance after", IERC20(memeToken).balanceOf(address(bob)));
    }
}
