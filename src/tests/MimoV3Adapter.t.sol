pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/UniV3Adapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract MimoV3AdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    UniV3Adapter adapter;
    address payable WIOTX = payable(0xA00744882684C3e4747faEFD68D283eA44099D03);
    address WEN = 0x6C0bf4b53696b5434A0D21C7D13Aa3cbF754913E;
    address USDC = 0x3B2bf2b523f54C4E454F08Aa286D03115aFF326c;
    address pool = 0x8Ba209a81aa57691971d7eAee166bC249CfbbD90;

    address amy = vm.rememberKey(1);

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("IOTEX_RPC_URL"));
        adapter = new UniV3Adapter(WIOTX);
    }

    function test_swapWENtoUSDC() public {
        vm.startPrank(amy);
        uint256 amount = 0.1 * 10 ** 18;
        deal(WEN, amy, amount);
        IERC20(WEN).approve(tokenApprove, amount);

        console2.log("token0 balance before", IERC20(WEN).balanceOf(address(amy)));
        console2.log("token1 balance before", IERC20(USDC).balanceOf(address(amy)));

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WEN)));
        swapInfo.baseRequest.toToken = USDC;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(false, uint88(10000), pool)));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(0, abi.encode(WEN, USDC, uint24(2500)));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WEN)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("token0 balance after", IERC20(WEN).balanceOf(address(amy)));
        console2.log("token1 balance after", IERC20(USDC).balanceOf(address(amy)));
    }

    function test_swapUSDCtoWEN() public {
        vm.startPrank(amy);
        uint256 amount = 1 * 10 ** 6;
        deal(USDC, amy, amount);
        IERC20(USDC).approve(tokenApprove, amount);

        console2.log("token0 balance before", IERC20(USDC).balanceOf(address(amy)));
        console2.log("token1 balance before", IERC20(WEN).balanceOf(address(amy)));

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC)));
        swapInfo.baseRequest.toToken = WEN;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(false, uint88(10000), pool)));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(0, abi.encode(USDC, WEN, uint24(2500)));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("token0 balance after", IERC20(USDC).balanceOf(address(amy)));
        console2.log("token1 balance after", IERC20(WEN).balanceOf(address(amy)));
    }
}
