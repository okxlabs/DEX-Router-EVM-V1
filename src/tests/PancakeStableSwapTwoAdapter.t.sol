// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/PancakeStableSwapTwoAdapter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

/// @title PancakeStableSwapTwoAdapterTest
/// @notice Do the usability test of PancakeStableSwapTwoAdapter
/// @dev Explain to a developer any extra details

contract PancakeStableSwapTwoAdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x9333C74BDd1E118634fE5664ACA7a9710b108Bab));
    address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;
    PancakeStableSwapTwoAdapter adapter;

    address payable WBNB = payable (0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address USDX = 0xf3527ef8dE265eAa3716FB312c12847bFBA66Cef;
    address BSCUSD = 0x55d398326f99059fF775485246999027B3197955;
    address pool = 0xe1CF7B307D1136E12Dc5C21aa790648E3b512F56;
    address amy = vm.rememberKey(1);

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

    function setUp() public {
        vm.createSelectFork(vm.envString("BNB_RPC_URL"));
        adapter = new PancakeStableSwapTwoAdapter(WBNB);
    }

    function test_USDX2BSCUSD() public user(amy){
        deal(USDX, amy, 1 ether);
        IERC20(USDX).approve(tokenApprove, 1 ether);
        uint256 amount = IERC20(USDX).balanceOf(amy);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDX)));
        swapInfo.baseRequest.toToken = BSCUSD;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(pool))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(address(USDX), address(BSCUSD), 1, 0);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDX)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        console2.log("USDX balance before", IERC20(USDX).balanceOf(address(amy)));
        console2.log("BSCUSD balance before", IERC20(BSCUSD).balanceOf(address(amy)));
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
        console2.log("USDX balance after", IERC20(USDX).balanceOf(address(amy)));
        console2.log("BSCUSD balance after", IERC20(BSCUSD).balanceOf(address(amy)));
    }

    function test_BSCUSD2USDX() public user(amy){
        deal(BSCUSD, amy, 1 ether);
        IERC20(BSCUSD).approve(tokenApprove, 1 ether);
        uint256 amount = IERC20(BSCUSD).balanceOf(amy);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(BSCUSD)));
        swapInfo.baseRequest.toToken = USDX;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(pool))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(address(BSCUSD), address(USDX), 0, 1);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(BSCUSD)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        console2.log("USDX balance before", IERC20(USDX).balanceOf(address(amy)));
        console2.log("BSCUSD balance before", IERC20(BSCUSD).balanceOf(address(amy)));
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
        console2.log("USDX balance after", IERC20(USDX).balanceOf(address(amy)));
        console2.log("BSCUSD balance after", IERC20(BSCUSD).balanceOf(address(amy)));
    }
}