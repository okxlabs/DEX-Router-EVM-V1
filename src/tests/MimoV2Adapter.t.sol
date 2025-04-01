pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/UniAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract MimoV2AdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address TREX = 0xB01b6E19C4B26810c7bD98879C8854F7e0519507;
    address WIOTX = 0xA00744882684C3e4747faEFD68D283eA44099D03;
    address WIOTX_TREX = 0x3843C3FBdC1FdEA1971c0005A2627CAf5bB89e49;

    address ATOR = 0xD902EA227fF15A75eaB1D09282860daBFff9B46A;
    address WEN = 0x6C0bf4b53696b5434A0D21C7D13Aa3cbF754913E;
    address ATOR_WEN = 0x12Cf12670E0e6318475b541fE71DB21c1DCF4f7D;

    address amy = vm.rememberKey(1);
    UniAdapter adapter;

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("IOTEX_RPC_URL"));
        adapter = new UniAdapter();
    }

    function test_swapWENtoATOR() public {
        vm.startPrank(amy);
        uint256 amount = 0.1 * 10 ** 18;
        deal(WEN, amy, amount);
        IERC20(WEN).approve(tokenApprove, amount);

        console2.log("token0 balance before", IERC20(WEN).balanceOf(address(amy)));
        console2.log("token1 balance before", IERC20(ATOR).balanceOf(address(amy)));
        
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WEN)));
        swapInfo.baseRequest.toToken = ATOR;
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
        // direct interaction with vault
        swapInfo.batches[0][0].assetTo[0] = address(ATOR_WEN);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(false, uint88(10000), ATOR_WEN)));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "0x";
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WEN)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("token0 balance after", IERC20(WEN).balanceOf(address(amy)));
        console2.log("token1 balance after", IERC20(ATOR).balanceOf(address(amy)));
    }

    function test_swapWIOTXtoTREX() public {
        vm.startPrank(amy);
        uint256 amount = 0.1 * 10 ** 18;
        deal(WIOTX, amy, amount);
        IERC20(WIOTX).approve(tokenApprove, amount);

        console2.log("token0 balance before", IERC20(WIOTX).balanceOf(address(amy)));
        console2.log("token1 balance before", IERC20(TREX).balanceOf(address(amy)));
        
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WIOTX)));
        swapInfo.baseRequest.toToken = TREX;
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
        // direct interaction with vault
        swapInfo.batches[0][0].assetTo[0] = address(WIOTX_TREX);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WIOTX_TREX))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "0x";
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WIOTX)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("token0 balance after", IERC20(WIOTX).balanceOf(address(amy)));
        console2.log("token1 balance after", IERC20(TREX).balanceOf(address(amy)));
    }

    function test_swapTREXtoWIOTX() public {
        vm.startPrank(amy);
        uint256 amount = 0.1 * 10 ** 18;
        deal(TREX, amy, amount);
        console2.log("token0 balance before", IERC20(WIOTX).balanceOf(address(amy)));
        console2.log("token1 balance before", IERC20(TREX).balanceOf(address(amy)));
        IERC20(TREX).approve(tokenApprove, amount);
        
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(TREX)));
        swapInfo.baseRequest.toToken = WIOTX;
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
        // direct interaction with vault
        swapInfo.batches[0][0].assetTo[0] = address(WIOTX_TREX);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(WIOTX_TREX))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "0x";
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(TREX)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("token0 balance after", IERC20(WIOTX).balanceOf(address(amy)));
        console2.log("token1 balance after", IERC20(TREX).balanceOf(address(amy)));
    }
}
