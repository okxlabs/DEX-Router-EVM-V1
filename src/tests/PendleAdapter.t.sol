// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/PendleAdapter.sol";
import "@dex/interfaces/IPendle.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract PendleAdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0xf332761c673b59B21fF6dfa8adA44d78c12dEF09));
    address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
    address pendleRouter = 0x00000000005BBB0EF59571E58418F9a4357b68A0; //arb

    address ezETH = 0x2416092f143378750bb29b79eD961ab195CcEea5;
    address ezETH_PT = 0x8EA5040d423410f1fdc363379Af88e1DB5eA1C34;
    address ezETH_YT = 0x05735B65686635F5C87AA9D2dae494Fb2E838f38;
    address market = 0x5E03C94Fc5Fb2E21882000A96Df0b63d2c4312e2;
    
    address bob = vm.rememberKey(1);

    PendleAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ARB_RPC_URL"));
        adapter = new PendleAdapter(pendleRouter);
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("ezETH balance before", IERC20(ezETH).balanceOf(address(_user)));
        console2.log("ezETH_PT balance before", IERC20(ezETH_PT).balanceOf(address(_user)));
        console2.log("ezETH_YT balance before", IERC20(ezETH_YT).balanceOf(address(_user)));
        _;
        console2.log("ezETH balance after", IERC20(ezETH).balanceOf(address(_user)));
        console2.log("ezETH_PT balance after", IERC20(ezETH_PT).balanceOf(address(_user)));
        console2.log("ezETH_YT balance after", IERC20(ezETH_YT).balanceOf(address(_user)));
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    // function test_swapezETHtoezETHPt() public user(bob) tokenBalance(bob) {
    //     deal(ezETH, bob, 1 ether);
    //     IERC20(ezETH).approve(tokenApprove, 1 ether);

    //     uint256 amount = IERC20(ezETH).balanceOf(bob);

    //     ApproxParams memory params = ApproxParams({
    //         guessMin: 0, // adjust as desired
    //         guessMax: type(uint256).max, // adjust as desired
    //         guessOffchain: 0, // strictly 0
    //         maxIteration: 256, // adjust as desired
    //         eps: 1e14 // max 0.01% unused, adjust as desired
    //     });
    //     SwapInfo memory swapInfo;
    //     swapInfo.baseRequest.fromToken = uint256(uint160(address(ezETH)));
    //     swapInfo.baseRequest.toToken = ezETH_PT;
    //     swapInfo.baseRequest.fromTokenAmount = amount;
    //     swapInfo.baseRequest.minReturnAmount = 0;
    //     swapInfo.baseRequest.deadLine = block.timestamp;

    //     swapInfo.batchesAmount = new uint[](1);
    //     swapInfo.batchesAmount[0] = amount;

    //     swapInfo.batches = new DexRouter.RouterPath[][](1);
    //     swapInfo.batches[0] = new DexRouter.RouterPath[](1);
    //     swapInfo.batches[0][0].mixAdapters = new address[](1);
    //     swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
    //     swapInfo.batches[0][0].assetTo = new address[](1);
    //     // direct interaction with adapter
    //     swapInfo.batches[0][0].assetTo[0] = address(adapter);
    //     swapInfo.batches[0][0].rawData = new uint[](1);
    //     swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(market))));
    //     swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
    //     swapInfo.batches[0][0].extraData[0] = abi.encode(address(ezETH), address(ezETH_PT), true, true, abi.encode(params));
    //     swapInfo.batches[0][0].fromToken = uint256(uint160(address(ezETH)));

    //     swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

    //     dexRouter.smartSwapByOrderId(
    //         swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
    //     );
    // }

    // function test_swapezETHtoezETHYt() public user(bob) tokenBalance(bob) {
    //     deal(ezETH, bob, 1 ether);
    //     IERC20(ezETH).approve(tokenApprove, 1 ether);

    //     uint256 amount = IERC20(ezETH).balanceOf(bob);

    //     ApproxParams memory params = ApproxParams({
    //         guessMin: 0, // adjust as desired
    //         guessMax: type(uint256).max, // adjust as desired
    //         guessOffchain: 0, // strictly 0
    //         maxIteration: 256, // adjust as desired
    //         eps: 1e14 // max 0.01% unused, adjust as desired
    //     });
    //     SwapInfo memory swapInfo;
    //     swapInfo.baseRequest.fromToken = uint256(uint160(address(ezETH)));
    //     swapInfo.baseRequest.toToken = ezETH_YT;
    //     swapInfo.baseRequest.fromTokenAmount = amount;
    //     swapInfo.baseRequest.minReturnAmount = 0;
    //     swapInfo.baseRequest.deadLine = block.timestamp;

    //     swapInfo.batchesAmount = new uint[](1);
    //     swapInfo.batchesAmount[0] = amount;

    //     swapInfo.batches = new DexRouter.RouterPath[][](1);
    //     swapInfo.batches[0] = new DexRouter.RouterPath[](1);
    //     swapInfo.batches[0][0].mixAdapters = new address[](1);
    //     swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
    //     swapInfo.batches[0][0].assetTo = new address[](1);
    //     // direct interaction with adapter
    //     swapInfo.batches[0][0].assetTo[0] = address(adapter);
    //     swapInfo.batches[0][0].rawData = new uint[](1);
    //     swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(market))));
    //     swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
    //     swapInfo.batches[0][0].extraData[0] = abi.encode(address(ezETH), address(ezETH_YT), true, false, abi.encode(params));
    //     swapInfo.batches[0][0].fromToken = uint256(uint160(address(ezETH)));

    //     swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

    //     dexRouter.smartSwapByOrderId(
    //         swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
    //     );
    // }

    // function test_swapezETHPtoezETH() public user(bob) tokenBalance(bob) {
    //     deal(ezETH_PT, bob, 1 ether);
    //     IERC20(ezETH_PT).approve(tokenApprove, 1 ether);

    //     uint256 amount = IERC20(ezETH_PT).balanceOf(bob);

    //     SwapInfo memory swapInfo;
    //     swapInfo.baseRequest.fromToken = uint256(uint160(address(ezETH_PT)));
    //     swapInfo.baseRequest.toToken = ezETH;
    //     swapInfo.baseRequest.fromTokenAmount = amount;
    //     swapInfo.baseRequest.minReturnAmount = 0;
    //     swapInfo.baseRequest.deadLine = block.timestamp;

    //     swapInfo.batchesAmount = new uint[](1);
    //     swapInfo.batchesAmount[0] = amount;

    //     swapInfo.batches = new DexRouter.RouterPath[][](1);
    //     swapInfo.batches[0] = new DexRouter.RouterPath[](1);
    //     swapInfo.batches[0][0].mixAdapters = new address[](1);
    //     swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
    //     swapInfo.batches[0][0].assetTo = new address[](1);
    //     // direct interaction with adapter
    //     swapInfo.batches[0][0].assetTo[0] = address(adapter);
    //     swapInfo.batches[0][0].rawData = new uint[](1);
    //     swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(market))));
    //     swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
    //     swapInfo.batches[0][0].extraData[0] = abi.encode(address(ezETH_PT), address(ezETH), false, true, "");
    //     swapInfo.batches[0][0].fromToken = uint256(uint160(address(ezETH_PT)));

    //     swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

    //     dexRouter.smartSwapByOrderId(
    //         swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
    //     );
    // }

    function test_swapezETHYtoezETH() public user(bob) tokenBalance(bob) {
        deal(ezETH_YT, bob, 1 ether);
        IERC20(ezETH_YT).approve(tokenApprove, 1 ether);

        uint256 amount = IERC20(ezETH_YT).balanceOf(bob);

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(ezETH_YT)));
        swapInfo.baseRequest.toToken = ezETH;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(market))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(address(ezETH_YT), address(ezETH), false, false, "");
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(ezETH_YT)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

}
