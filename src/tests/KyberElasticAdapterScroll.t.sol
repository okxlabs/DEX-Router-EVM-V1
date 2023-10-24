// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/KyberElasticAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

//unit test
contract KyberElasticAdapterScrollTest is Test {
    KyberElasticAdapter adapter;
    address WETH = 0x5300000000000000000000000000000000000004;
    address USDT = 0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df;
    address USDC = 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4;
    address USDT_USDC = 0x77D607915D5bb744C9DF049c2144f48Aa9bb2e30;
    address WETH_USDC = 0xB3DC50fa5E530a770fC24f6761B69845844dA004;
    address rick = vm.rememberKey(1);

    function setUp() public {
        vm.createSelectFork(vm.envString("SCROLL_RPC_URL"), 147120);
        adapter = new KyberElasticAdapter(payable(WETH));
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }
    modifier tokenBalance(address fromToken) {
        deal(fromToken, rick, 100 * 10 ** 6);
        console2.log("USDC balance before",IERC20(USDC).balanceOf(address(rick)));
        console2.log("USDT balance before",IERC20(USDT).balanceOf(address(rick)));
        _;
        console2.log("USDC balance after",IERC20(USDC).balanceOf(address(rick)));
        console2.log("USDT balance after",IERC20(USDT).balanceOf(address(rick)));
    }

    modifier tokenBalance1(address fromToken, uint256 amount) {
        deal(fromToken, rick, amount);
        console2.log("USDC balance before",IERC20(USDC).balanceOf(address(rick)));
        console2.log("WETH balance before",IERC20(WETH).balanceOf(address(rick)));
        _;
        console2.log("USDC balance after",IERC20(USDC).balanceOf(address(rick)));
        console2.log("WETH balance after",IERC20(WETH).balanceOf(address(rick)));
    }

    //USDC->USDT
    function test_swapUSDCForUSDT() public user(rick) tokenBalance(USDC) {
        IERC20(USDC).transfer(address(adapter), IERC20(USDC).balanceOf(rick));
        bytes memory data = abi.encode(USDC, USDT, uint24(0));
        adapter.sellBase(rick, USDT_USDC, abi.encode(uint160(0), data));
    }

    //USDT->USDC
    function test_swapUSDTForUSDC() public user(rick) tokenBalance(USDT) {
        IERC20(USDT).transfer(address(adapter), IERC20(USDT).balanceOf(rick));
        bytes memory data = abi.encode(USDT, USDC, uint24(0));
        adapter.sellBase(rick, USDT_USDC, abi.encode(uint160(0), data));
    }

    //USDC->WETH
    function test_swapUSDCForWETH() public user(rick) tokenBalance1(USDC, 100 * 10 ** 6)
    {
        IERC20(USDC).transfer(address(adapter), IERC20(USDC).balanceOf(rick));
        bytes memory data = abi.encode(USDC, WETH, uint24(0));
        adapter.sellBase(rick, WETH_USDC, abi.encode(uint160(0), data));
    }

    //WETH->USDC
    function test_swapWETHForUSDC() public user(rick) tokenBalance1(WETH, 1 ether)
    {
        IERC20(WETH).transfer(address(adapter), IERC20(WETH).balanceOf(rick));
        bytes memory data = abi.encode(WETH, USDC, uint24(0));
        adapter.sellQuote(rick, WETH_USDC, abi.encode(uint160(0), data));
    }
}

// integrate test
contract KyberElasticAdapterScrollTestIntegrate is Test {
    DexRouter dexRouter =
        DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;
    address USDT_USDC = 0x77D607915D5bb744C9DF049c2144f48Aa9bb2e30;
    address USDT = 0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df;
    address USDC = 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4;
    address WETH = 0x5300000000000000000000000000000000000004;

    KyberElasticAdapter adapter;
    address morty = vm.rememberKey(1);

    function setUp() public {
        vm.createSelectFork(vm.envString("SCROLL_RPC_URL"), 147120);
        adapter = new KyberElasticAdapter(payable(WETH));
    }

    struct SwapInfo {
        uint orderId;
        DexRouter.BaseRequest baseRequest;
        uint[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }
    modifier tokenBalance(address fromToken) {
        deal(fromToken, morty, 100 * 10 ** 6);
        console2.log("USDC balance before",IERC20(USDC).balanceOf(address(morty)));
        console2.log("USDT balance before",IERC20(USDT).balanceOf(address(morty)));
        _;
        console2.log("USDC balance after",IERC20(USDC).balanceOf(address(morty)));
        console2.log("USDT balance after",IERC20(USDT).balanceOf(address(morty)));
    }

    function test_swapUSDCForUSDT() public user(morty) tokenBalance(USDC) {
        uint fromAmount = IERC20(USDC).balanceOf(morty);
        IERC20(USDC).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(USDC));
        swapInfo.baseRequest.toToken = USDT;
        swapInfo.baseRequest.fromTokenAmount = fromAmount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        //batchsAmount
        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = fromAmount;

        //batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        //mixAdapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        //assertTo
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        //rawData
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint(
            bytes32(abi.encodePacked(false, uint88(10000), address(USDT_USDC)))
        );
        //moreInfo
        bytes memory data = abi.encode(USDC, USDT, uint24(0));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(uint160(0), data);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(USDC)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_swapUSDTForUSDC() public user(morty) tokenBalance(USDT) {
        uint fromAmount = IERC20(USDT).balanceOf(morty);
        IERC20(USDT).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(USDT));
        swapInfo.baseRequest.toToken = USDC;
        swapInfo.baseRequest.fromTokenAmount = fromAmount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        //batchsAmount
        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = fromAmount;

        //batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        //mixAdapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        //assertTo
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        //rawData
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint(
            bytes32(abi.encodePacked(false, uint88(10000), address(USDT_USDC)))
        );
        //moreInfo
        bytes memory data = abi.encode(USDT, USDC, uint24(0));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(uint160(0), data);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(USDT)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }
}



