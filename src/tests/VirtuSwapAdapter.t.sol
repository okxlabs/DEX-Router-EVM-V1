// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/VirtuSwapAdapter.sol";

contract VirtuSwapAdapterTest is Test {
    using SafeERC20 for IERC20;
    VirtuSwapAdapter adapter;
    address tester = 0x1111111111111111111111111111111111111111;
    address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
    DexRouter dexRouter =
        DexRouter(payable(0xf332761c673b59B21fF6dfa8adA44d78c12dEF09)); // arbtrium
    address pool = 0x3CF3838FEF4541A6eeDaE71fa5626673b7E78aC2;
    address wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f; // token0
    address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // token1

    uint256 wethAmount = 6436380231282357;
    uint256 wbtcAmount = 25202;

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

    struct SwapInfo {
        uint orderId;
        DexRouter.BaseRequest baseRequest;
        uint[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function _fundTesterAndApprove(
        address tokenX,
        uint256 amountX,
        address tokenY,
        uint256 amountY
    ) private user(tester) {
        // fund tester and approve allowance to tokenApprove
        deal(tokenX, tester, amountX);
        deal(tokenY, tester, amountY);

        IERC20(tokenX).safeApprove(tokenApprove, amountX);
        IERC20(tokenY).safeApprove(tokenApprove, amountY);

        assertEq(IERC20(tokenX).allowance(tester, tokenApprove), amountX);
        assertEq(IERC20(tokenY).allowance(tester, tokenApprove), amountY);
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

    function setUp() public {
        vm.createSelectFork(vm.envString("ARB_RPC_URL"), 266500702 - 1);
        adapter = new VirtuSwapAdapter();
        _fundTesterAndApprove(wbtc, wbtcAmount, weth, wethAmount);
    }

    function test_weth_2_wbtc()
        public
        user(tester)
        swapLog(tester, weth, wbtc, wethAmount, wbtcAmount)
    {
        // input / output value should match exactly:
        // https://arbiscan.io/tx/0x5bc02ceb940860e3b161684031807f2dc4585db04407fd7e3807f47e7852f28e
        _execSwap(weth, wbtc, wethAmount);
    }

    function test_wbtc_2_weth()
        public
        user(tester)
        swapLog(tester, wbtc, weth, wbtcAmount, 0)
    {
        _execSwap(wbtc, weth, wbtcAmount);
    }
}
