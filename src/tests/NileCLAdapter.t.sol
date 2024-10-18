// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/NileCLAdapter.sol";

contract NileCLAdapterTest is Test {
    using SafeERC20 for IERC20;
    NileCLAdapter adapter;
    DexRouter dexRouter =
        DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;
    address usdt = 0xA219439258ca9da29E9Cc4cE5596924745e12B93; // token0
    address weth = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f; // token1
    address tester = 0x1111111111111111111111111111111111111111;
    address pool = 0x27ED78122B8eF363F4EF5B3aFe197e0c4A2Fa514;

    uint256 usdtAmount = 619495488; // 619.495 usd
    uint256 wethAmount = 245112636459787848; // 0.24511 eth

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

    modifier swapLog(
        address account,
        address tokenIn,
        address tokenOut,
        uint256 assertAmountIn,
        uint256 assertAmountOut
    ) {
        uint256 inBefore = IERC20(tokenIn).balanceOf(account);
        uint256 outBefore = IERC20(tokenOut).balanceOf(account);

        _;

        uint256 inAmount = inBefore - IERC20(tokenIn).balanceOf(account);
        uint256 outAmount = IERC20(tokenOut).balanceOf(account) - outBefore;
        string memory fmtStr = string(
            abi.encodePacked(
                "Swapped [%s] ",
                IERC20(tokenIn).symbol(),
                " for [%s] ",
                IERC20(tokenOut).symbol()
            )
        );
        console2.log(fmtStr, inAmount, outAmount);
        if (assertAmountIn > 0) {
            assertEq(inAmount, assertAmountIn);
        }
        if (assertAmountOut > 0) {
            assertEq(outAmount, assertAmountOut);
        }
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("LINEA_RPC_URL"), 10728479 - 1);
        adapter = new NileCLAdapter();
        _fundTesterAndApprove();
    }

    function _fundTesterAndApprove() private user(tester) {
        deal(usdt, tester, usdtAmount);
        deal(weth, tester, wethAmount);

        IERC20(usdt).safeApprove(tokenApprove, usdtAmount);
        IERC20(weth).safeApprove(tokenApprove, wethAmount);

        assertEq(IERC20(usdt).balanceOf(tester), usdtAmount);
        assertEq(IERC20(weth).balanceOf(tester), wethAmount);
    }

    function _execSwap(
        address fromToken,
        address toToken,
        uint256 amount
    ) private {
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(fromToken));
        swapInfo.baseRequest.toToken = toToken;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        //batchsAmount
        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        //batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        //mixAdapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        //assetTo
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        //rawData
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint(
            bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(pool)))
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(fromToken, toToken);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(fromToken)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_usdt_2_weth()
        public
        user(tester)
        swapLog(tester, usdt, weth, usdtAmount, wethAmount)
    {
        // https://lineascan.build/tx/0x53086f44cde7e571e35ebb74fddde65c32c8cca73201ba135e7f2fd2b0dbb4c7
        _execSwap(usdt, weth, usdtAmount);
    }

    function test_weth_2_usdt()
        public
        user(tester)
        swapLog(tester, weth, usdt, 0, 0)
    {
        _execSwap(weth, usdt, wethAmount);
    }
}
