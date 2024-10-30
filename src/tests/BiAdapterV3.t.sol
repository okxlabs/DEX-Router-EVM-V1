// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/BiAdapterV3.sol";

contract BiAdapterV3Test is Test {
    using SafeERC20 for IERC20;
    BiAdapterV3 adapter;
    DexRouter dexRouter =
        DexRouter(payable(0x9333C74BDd1E118634fE5664ACA7a9710b108Bab));
    address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;
    address usdt = 0x55d398326f99059fF775485246999027B3197955; // tokenX
    address wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // tokenY
    address tester = 0x1111111111111111111111111111111111111111;
    address pool = 0xd647583EAdC9D6BdFfB88Be8F47d8F858fC2a61c;
    uint256 wbnbAmount = 994081203933085;
    uint256 usdtAmount = 575849242581493889;

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

    function _fundTesterAndApprove() private user(tester) {
        // fund tester and approve allowance to tokenApprove
        deal(wbnb, tester, wbnbAmount);
        deal(usdt, tester, usdtAmount);

        IERC20(usdt).safeApprove(tokenApprove, usdtAmount);
        IERC20(wbnb).safeApprove(tokenApprove, wbnbAmount);

        assertEq(IERC20(usdt).allowance(tester, tokenApprove), usdtAmount);
        assertEq(IERC20(wbnb).allowance(tester, tokenApprove), wbnbAmount);
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
        swapInfo.batches[0][0].extraData[0] = abi.encode(fromToken, toToken, 1);
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

    function test_usdt_2_wbnb()
        public
        user(tester)
        swapLog(tester, usdt, wbnb, usdtAmount, wbnbAmount)
    {
        // intput / output amount shoud be exactly match with this txn:
        // https://bscscan.com/tx/0x1b01e2de8d8771f0727c22c80df6fd6fc0f64d0ea004aac36b4af86dc3ce7e0d

        _execSwap(usdt, wbnb, usdtAmount);
    }

    function test_wbnb_2_usdt()
        public
        user(tester)
        swapLog(tester, wbnb, usdt, 0, 0)
    {
        _execSwap(wbnb, usdt, wbnbAmount);
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 42732345);
        adapter = new BiAdapterV3();
        _fundTesterAndApprove();
    }
}
