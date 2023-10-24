pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/SyncSwapAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract SyncswapAdapterReuseTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address USDT = 0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df;
    address USDC = 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4;
    address WETH = 0x5300000000000000000000000000000000000004;
    address USDC_USDT = 0x2076d4632853FB165Cf7c7e7faD592DaC70f4fe1;
    address USDC_WETH = 0x814A23B053FD0f102AEEda0459215C2444799C70;
    address constant VAULT = 0x7160570BB153Edd0Ea1775EC2b2Ac9b65F1aB61B;
    address arnaud = vm.rememberKey(1);

    SyncSwapAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("SCROLL_RPC_URL"), 151858);
        adapter = new SyncSwapAdapter();
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance() {
        console2.log("USDC balance before", IERC20(USDC).balanceOf(address(arnaud)));
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(arnaud)));
        console2.log("WETH balance before", IERC20(WETH).balanceOf(address(arnaud)));
        _;
        console2.log("USDC balance after", IERC20(USDC).balanceOf(address(arnaud)));
        console2.log("USDT balance after", IERC20(USDT).balanceOf(address(arnaud)));
        console2.log("WETH balance after", IERC20(WETH).balanceOf(address(arnaud)));
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_swapUSDCtoUSDT() public user(arnaud) tokenBalance {
        deal(USDC, arnaud, 1 * 10 ** 6);
        IERC20(USDC).approve(tokenApprove, 1 * 10 ** 6);

        uint256 amount = IERC20(USDC).balanceOf(arnaud);
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
        // direct interaction with vault
        swapInfo.batches[0][0].assetTo[0] = address(VAULT);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(false, uint88(10000), address(USDC_USDT))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDC);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_swapWETHtoUSDC() public user(arnaud) tokenBalance {
        deal(WETH, arnaud, 1 ether);
        IERC20(WETH).approve(tokenApprove, 1 ether);

        uint256 amount = IERC20(WETH).balanceOf(arnaud);
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
        swapInfo.batches[0][0].assetTo[0] = address(VAULT);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(false, uint88(10000), address(USDC_WETH))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(WETH);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }
}
