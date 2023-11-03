// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/SolidlyseriesAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract SanctuaryAdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address USDT = 0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df;
    address USDC = 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4;
    address WETH = 0x5300000000000000000000000000000000000004;
    address USDC_USDT = 0x48AcbF1db807c560E454165f80F1BD12850ADBa8;
    address USDC_WETH = 0x6079D5f59708B8Dd32D978821fd1B44920a51bCb;
    
    address bob = vm.rememberKey(1);

    SolidlyseriesAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("SCROLL_RPC_URL"), 328275);
        adapter = new SolidlyseriesAdapter();
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("USDC balance before", IERC20(USDC).balanceOf(address(_user)));
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(_user)));
        console2.log("WETH balance before", IERC20(WETH).balanceOf(address(_user)));
        _;
        console2.log("USDC balance after", IERC20(USDC).balanceOf(address(_user)));
        console2.log("USDT balance after", IERC20(USDT).balanceOf(address(_user)));
        console2.log("WETH balance after", IERC20(WETH).balanceOf(address(_user)));
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_swapUSDCtoUSDT() public user(bob) tokenBalance(bob) {
        deal(USDC, bob, 1 * 10 ** 6);
        IERC20(USDC).approve(tokenApprove, 1 * 10 ** 6);

        uint256 amount = IERC20(USDC).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC)));
        swapInfo.baseRequest.toToken = USDT;
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
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(USDC_USDT);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(USDC_USDT))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_swapWETHtoUSDC() public user(bob) tokenBalance(bob) {
        deal(WETH, bob, 0.001 ether);
        IERC20(WETH).approve(tokenApprove, 0.001 ether);

        uint256 amount = IERC20(WETH).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WETH)));
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
        swapInfo.batches[0][0].assetTo[0] = address(USDC_WETH);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(USDC_WETH))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }
}
