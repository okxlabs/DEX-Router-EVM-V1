pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/ThenaV2Adapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract ThenaV2AdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x9333C74BDd1E118634fE5664ACA7a9710b108Bab));
    address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;

    address USDT = 0x55d398326f99059fF775485246999027B3197955;
    address USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address WETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address USDC_USDT = 0x1b9a1120a17617D8eC4dC80B921A9A1C50Caef7d;
    address USDT_WETH = 0xa60a504d92a1C95bda729C3F745B361cA822d6dd;

    address POOL_DEPLOYER = 0xc89F69Baa3ff17a842AB2DE89E5Fc8a8e2cc7358;
    bytes32 POOL_INIT_CODE_HASH = 0xd61302e7691f3169f5ebeca3a0a4ab8f7f998c01e55ec944e62cfb1109fd2736;

    address arnaud = vm.rememberKey(1);

    ThenaV2Adapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 33130088);
        adapter = new ThenaV2Adapter(POOL_DEPLOYER, POOL_INIT_CODE_HASH);
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
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(false, uint88(10000), address(USDC_USDT))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(uint160(0), abi.encode(address(USDC), address(USDT)));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_swapWETHtoUSDT() public user(arnaud) tokenBalance {
        deal(WETH, arnaud, 1 ether);
        IERC20(WETH).approve(tokenApprove, 1 ether);

        uint256 amount = IERC20(WETH).balanceOf(arnaud);
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
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(false, uint88(10000), address(USDT_WETH))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(uint160(0), abi.encode(address(WETH), address(USDT)));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

}
