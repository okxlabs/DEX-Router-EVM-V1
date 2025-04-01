// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/interfaces/IDODOV2.sol";
import "@dex/adapter/DODOV2Adapter.sol";

contract MIMSwapAdapterTest is Test {
    using SafeERC20 for IERC20;
    DexRouter dexRouter =
        DexRouter(payable(0xf332761c673b59B21fF6dfa8adA44d78c12dEF09)); //arb
    address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
    address pool = 0x17806bcf1a76cebd9FdA9C9Cca412c41b1F38b1C; // ARB/WETH
    address arb = 0x912CE59144191C1204E64559FE8253a0e49E6548; // Base token
    address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; //Quote token
    address tester = 0x1111111111111111111111111111111111111111;
    uint256 arbAmount = 380215365444612814;
    uint256 wethAmount = 74871850610666;
    DODOV2Adapter adapter;

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
        vm.createSelectFork(vm.envString("ARB_RPC_URL"), 273780603 - 1);
        adapter = new DODOV2Adapter();
        _fundTesterAndApprove(weth, wethAmount, arb, arbAmount);
    }

    function _getMoreInfo(
        address,
        address
    ) private pure returns (bytes memory) {
        return "0x";
    }

    function _execSwap(
        address fromToken,
        address toToken,
        uint256 amount
    ) private {
        uint8 direction;
        address baseToken = IDODOV2(pool)._BASE_TOKEN_();
        if (fromToken == baseToken) {
            // sellBase
            direction = 0x00;
        } else {
            // sellQuote
            direction = 0x80;
        }

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
        swapInfo.batches[0][0].assetTo[0] = address(pool);
        //rawData
        swapInfo.batches[0][0].rawData = new uint[](1);
        uint rd = uint(
            bytes32(abi.encodePacked(direction, uint88(10000), address(pool)))
        );
        swapInfo.batches[0][0].rawData[0] = rd;
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

    function test_arb_2_weth()
        public
        user(tester)
        swapLog(tester, arb, weth, arbAmount, wethAmount)
    {
        //https://arbiscan.io/tx/0x761635b001559dcf59526b6a690c022359e60b84f97f0d43585f5bd89597908a
        _execSwap(arb, weth, arbAmount);
    }

    function test_weth_2_arb()
        public
        user(tester)
        swapLog(tester, weth, arb, wethAmount, 0)
    {
        _execSwap(weth, arb, wethAmount);
    }
}
