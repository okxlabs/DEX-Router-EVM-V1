// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/AgniFinanceAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract AgniFinanceAdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address WMNT = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8; 
    address WETH = 0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111;
    address USDT = 0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE;

    address WMNT_USDT = 0xD08C50F7E69e9aeb2867DefF4A8053d9A855e26A;
    address WETH_USDT = 0x628f7131CF43e88EBe3921Ae78C4bA0C31872bd4;
    
    address bob = vm.rememberKey(1);

    AgniFinanceAdapter adapter;

    function setUp() public {
        //https://explorer.mantle.xyz/tx/0x49e745b9582d202b744a140c3a7e6aa8cd4a2bb2a282609b413696ddd899eebe
        vm.createSelectFork(vm.envString("MANTLE_RPC_URL"), 62825726-1);
        adapter = new AgniFinanceAdapter(payable(WMNT));
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("WMNT balance before", IERC20(WMNT).balanceOf(address(_user)));
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(_user)));
        console2.log("WETH balance before", IERC20(WETH).balanceOf(address(_user)));
        _;
        console2.log("WMNT balance after", IERC20(WMNT).balanceOf(address(_user)));
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

    function test_swapWMNTtoUSDT() public user(bob) tokenBalance(bob) {
        deal(WMNT, bob, 0.415 * 10 ** 18);
        IERC20(WMNT).approve(tokenApprove, 1 * 10 ** 18);

        uint256 amount = IERC20(WMNT).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WMNT)));
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
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WMNT_USDT))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(0, abi.encode(address(WMNT), address(USDT)));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WMNT)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_swapWETHtoUSDT() public user(bob) tokenBalance(bob) {
        deal(WETH, bob, 1 ether);
        IERC20(WETH).approve(tokenApprove, 1 ether);

        uint256 amount = IERC20(WETH).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WETH)));
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
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WETH_USDT))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(0, abi.encode(address(WETH), address(USDT)));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

}
