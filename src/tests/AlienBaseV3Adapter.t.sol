// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/AlienBaseV3Adapter.sol";

contract AlienBaseV3AdapterTest is Test {
    using SafeERC20 for IERC20;
    DexRouter dexRouter =
        DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58)); //base
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;
    address pool = 0xB27f110571c96B8271d91ad42D33A391A75E6030;
    address weth = 0x4200000000000000000000000000000000000006; //token0
    address usdc = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; //token1
    uint256 wethAmount = 46502901914085561;
    uint256 usdcAmount = 121788068;
    address tester = 0x1111111111111111111111111111111111111111;
    AlienBaseV3Adapter adapter;

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
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 21693942 - 1);
        adapter = new AlienBaseV3Adapter(payable(weth));
        _fundTesterAndApprove(weth, wethAmount, usdc, usdcAmount);
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

    function test_usdc_2_weth()
        public
        user(tester)
        swapLog(tester, usdc, weth, usdcAmount, wethAmount)
    {
        // the amount value shoud be match exactly with this txn
        // https://basescan.org/tx/0xc83216c8605b73c006a951cbd1a982086bdc4321e1f1756f9a7d0b35a8288ca0
        _execSwap(usdc, weth, usdcAmount);
    }

    function test_weth_2_usdc()
        public
        user(tester)
        swapLog(tester, weth, usdc, wethAmount, 0)
    {
        _execSwap(weth, usdc, wethAmount);
    }
}
