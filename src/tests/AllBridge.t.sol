// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/AllBridgeAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract AllBridgeAdapterTest is Test {
    using SafeERC20 for IERC20;
    DexRouter dexRouter = DexRouter(payable(0x156ACd2bc5fC336D59BAAE602a2BD9b5e20D6672));
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address router = 0x609c690e8F7D68a59885c9132e812eEbDaAf0c9e;

    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDT_LP = 0x7DBF07Ad92Ed4e26D5511b4F285508eBF174135D;

    address bob = vm.rememberKey(1);

    AllBridgeAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        adapter = new AllBridgeAdapter(payable(router));
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("USDC balance before", IERC20(USDC).balanceOf(address(_user)));
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(_user)));
        _;
        console2.log("USDC balance after", IERC20(USDC).balanceOf(address(_user)));
        console2.log("USDT balance after", IERC20(USDT).balanceOf(address(_user)));
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
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(USDT_LP))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(bytes32(uint256(uint160(USDC))), bytes32(uint256(uint160(USDT))));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_swapUSDTtoUSDC() public user(bob) tokenBalance(bob) {
        deal(USDT, bob, 1* 10 ** 6);
        IERC20(USDT).safeApprove(tokenApprove, 1 * 10 ** 6);

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
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(USDT_LP))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(bytes32(uint256(uint160(USDT))), bytes32(uint256(uint160(USDC))));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDT)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

}