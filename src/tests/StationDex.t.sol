// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/UniV3Adapter.sol";
import "@dex/adapter/DnyFeeAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract StationDexTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x127a986cE31AA2ea8E1a6a0F0D5b7E5dbaD7b0bE));
    address tokenApprove = 0x8b773D83bc66Be128c60e07E17C8901f7a64F000;


    address USDT = 0x1E4a5963aBFD975d8c9021ce480b42188849D41d;
    address USDC = 0x74b7F16337b8972027F6196A17a631aC6dE26d22;
    address WETH = 0x5A77f1443D16ee5761d310e38b62f77f726bC71c;
    address WOKB = 0xe538905cf8410324e03A5A23C1c177a474D59b2b;

    address USDT_WETH = 0xDd26d766020665F0e7c0d35532cF11EE8ED29d5A;
    address USDT_WOKB = 0x11E7C6Ff7aD159E179023bB771AEc61DB6D9234d;
    address USDT_USDC = 0x335Db3Ca65887958CA9d590acF287Ae770f81e72;
    address USDC_WOKB = 0x3C386527EB1b63A36f5eE32ae00612107C0F5E0B;


    address bob = vm.rememberKey(1);
    address userA = 0x28D940A148ed9b80b0F72f6Ac8d9F7313cC1eea0;
    UniV3Adapter adapter;

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    // struct SwapInfo{
    //     uint256 srcToken;
    //     uint256 amount;
    //     uint256 minReturn;
    //     bytes32[] pools;
    // }

    function setUp() public {
        vm.createSelectFork("https://rpc.xlayer.tech");
        adapter = UniV3Adapter(payable(0x7DAF29d2000fd29d5c4B28BD4f1956Fe9948D078));
        // adapter = new UniV3Adapter(payable(WOKB));
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("WETH balance before", IERC20(WETH).balanceOf(address(_user)));
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(_user)));
        console2.log("USDC balance before", IERC20(USDC).balanceOf(address(_user)));
        console2.log("WOKB balance before", IERC20(WOKB).balanceOf(address(_user)));
        _;
        console2.log("WETH balance after", IERC20(WETH).balanceOf(address(_user)));
        console2.log("USDT balance after", IERC20(USDT).balanceOf(address(_user)));
        console2.log("USDC balance after", IERC20(USDC).balanceOf(address(_user)));
        console2.log("WOKB balance after", IERC20(WOKB).balanceOf(address(_user)));
    }

    function test_swapUSDTForWETH() public user(bob) tokenBalance(bob) {
        deal(USDT, bob, 1 * 10 ** 6);
        IERC20(USDT).approve(tokenApprove, 1 * 10 ** 6);

        uint256 amount = IERC20(USDT).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDT)));
        swapInfo.baseRequest.toToken = WETH;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(USDT_WETH))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x

        swapInfo.batches[0][0].extraData[0] = abi.encode(uint160(0), abi.encode(address(USDT), address(WETH), uint24(0)));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDT)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_swapUSDTForWOKB() public user(bob) tokenBalance(bob) {
        deal(USDT, bob, 1 * 10 ** 6);
        IERC20(USDT).approve(tokenApprove, 1 * 10 ** 6);

        uint256 amount = IERC20(USDT).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDT)));
        swapInfo.baseRequest.toToken = WOKB;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(USDT_WOKB))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x

        swapInfo.batches[0][0].extraData[0] = abi.encode(uint160(0), abi.encode(address(USDT), address(WOKB), uint24(0)));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDT)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }
    
    function test_swapUSDTForUSDC() public user(bob) tokenBalance(bob) {
        deal(USDT, bob, 1 * 10 ** 6);
        IERC20(USDT).approve(tokenApprove, 1 * 10 ** 6);

        uint256 amount = IERC20(USDT).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDT)));
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
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(USDT_USDC))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x

        swapInfo.batches[0][0].extraData[0] = abi.encode(uint160(0), abi.encode(address(USDT), address(USDC), uint24(0)));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDT)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_swapUSDCForWOKB() public user(bob) tokenBalance(bob) {
        deal(USDC, bob, 1 * 10 ** 5);
        IERC20(USDC).approve(tokenApprove, 1 * 10 ** 5);

        uint256 amount = IERC20(USDC).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC)));
        swapInfo.baseRequest.toToken = WOKB;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(USDC_WOKB))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x

        swapInfo.batches[0][0].extraData[0] = abi.encode(uint160(0), abi.encode(address(USDC), address(WOKB), uint24(0)));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

}