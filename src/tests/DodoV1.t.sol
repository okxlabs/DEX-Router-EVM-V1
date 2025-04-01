// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/DODOV1Adapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract DODOV1AdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0xF3dE3C0d654FDa23daD170f0f320a92172509127));
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address helper = 0x533dA777aeDCE766CEAe696bf90f8541A4bA80Eb;

    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address pool = 0xC9f93163c99695c6526b799EbcA2207Fdf7D61aD;
    
    // address bob = vm.rememberKey(1);
    address bob = 0x6Fb624B48d9299674022a23d92515e76Ba880113;

    DODOV1Adapter adapter;

    function setUp() public {
        vm.createSelectFork(
            "https://rpc.ankr.com/eth"
        );
        // adapter = new DODOV1Adapter(payable(helper));
        adapter = DODOV1Adapter(0x22566Cbe18Fff9adEDF6AC70fd9feDCE95887927);
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
        deal(USDC, bob, 100000 * 10 ** 6);
        IERC20(USDC).approve(tokenApprove, 100000 * 10 ** 6);

        uint256 amount = 50000 * 10 ** 6;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(pool))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode("");
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_swapUSDTtoUSDC() public user(bob) tokenBalance(bob) {
        // deal(USDT, bob, 100000 * 10 ** 6);
        // IERC20(USDT).approve(tokenApprove, 100000 * 10 ** 6);
        SafeERC20.safeApprove(IERC20(USDT), tokenApprove, 100000 * 10 ** 6);

        uint256 amount = 50000 * 10 ** 6;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(pool))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode("");
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDT)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

}
