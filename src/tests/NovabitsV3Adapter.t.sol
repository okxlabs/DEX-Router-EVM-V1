// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/NovabitsV3Adapter.sol";

contract NovabitsV3AdapterTest is Test {
    using SafeERC20 for IERC20;
    DexRouter dexRouter =
        DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58)); //mantle
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address pool = 0xa59CB8E418424BC1CBDBf848Ac9C1DfC80bE94E8;
    address wmnt = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8; // token0
    address pi = 0xc1458e0f666299aC6eF2B35556ab3b7c10410eBC; // token1

    uint256 wmntAmount = 200000000000000000;
    uint256 piAmount = 640954451556901139146;
    address tester = 0x1111111111111111111111111111111111111111;

    NovabitsV3Adapter adapter;

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

    function setUp() public {
        vm.createSelectFork(vm.envString("MANTLE_RPC_URL"), 70746719 - 1);
        adapter = new NovabitsV3Adapter(payable(wmnt));
        _fundTesterAndApprove(wmnt, wmntAmount, pi, piAmount);
    }

    function _getMoreInfo(
        address fromToken,
        address toToken
    ) private pure returns (bytes memory moreInfo) {
        uint160 sqrtX96 = 0;
        uint24 fee = 0;
        bytes memory data = abi.encode(fromToken, toToken, fee);
        moreInfo = abi.encode(sqrtX96, data);
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
        swapInfo.batches[0][0].extraData[0] = _getMoreInfo(fromToken, toToken);
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

    function test_wmnt_2_pi()
        public
        user(tester)
        swapLog(tester, wmnt, pi, wmntAmount, piAmount)
    {
        // the input / output amount should be exactly match with this txn
        // https://mantlescan.info/tx/0x9da2ce85e1d675b10bc22cf71de24e531583055abf98c44e974898f7817f8f14
        _execSwap(wmnt, pi, wmntAmount);
    }

    function test_pi_2_wmnt()
        public
        user(tester)
        swapLog(tester, pi, wmnt, piAmount, 0)
    {
        _execSwap(pi, wmnt, piAmount);
    }
}
