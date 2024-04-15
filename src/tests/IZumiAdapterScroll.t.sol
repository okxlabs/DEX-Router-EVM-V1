// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/IzumiAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

//unit test
contract IZumiAdapterScrollTest is Test {
    IZumiAdapter adapter;
    address factory = 0x8c7d3063579BdB0b90997e18A770eaE32E1eBb08;
    address USDC_WETH = 0x8F8ed95B3B3eD2979d1ee528f38cA3e481a94dd9;
    address USDC = 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4;
    address WETH = 0x5300000000000000000000000000000000000004;
    address rick = vm.rememberKey(1);

    function setUp() public {
        vm.createSelectFork(vm.envString("SCROLL_RPC_URL"), 147120);
        adapter = new IZumiAdapter(payable(WETH), factory);
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }
    modifier tokenBalance(address fromToken, uint256 amount) {
        deal(fromToken, rick, amount);
        console2.log("USDC balance before",IERC20(USDC).balanceOf(address(rick)));
        console2.log("WETH balance before",IERC20(WETH).balanceOf(address(rick)));
        _;
        console2.log("USDC balance after",IERC20(USDC).balanceOf(address(rick)));
        console2.log("WETH balance after",IERC20(WETH).balanceOf(address(rick)));
    }

    //USDC->WETH
    function test_swapUSDCForWETH() public user(rick)tokenBalance(USDC, 100 * 10 ** 6)
    {
        IERC20(USDC).transfer(address(adapter), IERC20(USDC).balanceOf(rick));
        adapter.sellBase(rick, USDC_WETH, abi.encode(USDC, WETH));
    }

    //WETH->USDC
    function test_swapWETHForUSDC() public user(rick) tokenBalance(WETH, 1 ether)
    {
        IERC20(WETH).transfer(address(adapter), IERC20(WETH).balanceOf(rick));
        adapter.sellQuote(rick, USDC_WETH, abi.encode(WETH, USDC));
    }
}

//integrate test
contract IZumiAdapterScrollTestIntegrate is Test {
    DexRouter dexRouter =
        DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;
    address factory = 0x8c7d3063579BdB0b90997e18A770eaE32E1eBb08;
    address USDC_WETH = 0x8F8ed95B3B3eD2979d1ee528f38cA3e481a94dd9;
    address USDC = 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4;
    address WETH = 0x5300000000000000000000000000000000000004;

    IZumiAdapter adapter;
    address morty = vm.rememberKey(1);

    function setUp() public {
        vm.createSelectFork(vm.envString("SCROLL_RPC_URL"), 147120);
        adapter = new IZumiAdapter(payable(WETH), factory);
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

    modifier tokenBalance(address fromToken, uint256 amount) {
        deal(fromToken, morty, amount);
        console2.log("USDC balance before",IERC20(USDC).balanceOf(address(morty)));
        console2.log("WETH balance before",IERC20(WETH).balanceOf(address(morty)));
        _;
        console2.log("USDC balance after",IERC20(USDC).balanceOf(address(morty)));
        console2.log("WETH balance after",IERC20(WETH).balanceOf(address(morty)));
    }   


    function test_swapUSDCForWETH() public user(morty) tokenBalance(USDC, 100 * 10 ** 6)
    {
        uint fromAmount = IERC20(USDC).balanceOf(morty);
        IERC20(USDC).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(USDC));
        swapInfo.baseRequest.toToken = WETH;
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
            bytes32(
                abi.encodePacked(uint8(0x00), uint88(10000), address(USDC_WETH))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDC, WETH);
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

    function test_swapWETHForUSDC() public user(morty) tokenBalance(WETH, 1 ether)
    {
        uint fromAmount = IERC20(WETH).balanceOf(morty);
        IERC20(WETH).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(WETH));
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
            bytes32(
                abi.encodePacked(uint8(0x80), uint88(10000), address(USDC_WETH))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(WETH, USDC);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(WETH)));
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
