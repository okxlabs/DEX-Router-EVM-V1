// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/SovereignPoolAdapter.sol";

contract SovereignPoolAdapterTest is Test {
    using SafeERC20 for IERC20;
    DexRouter dexRouter =
        DexRouter(payable(0x7D0CcAa3Fac1e5A943c5168b6CEd828691b46B36)); // dex router v3 , eth
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    uint256 blkHeight = 21378468;
    address pool = 0xD9a406DBC1a301B0D2eD5bA0d9398c4debe68202;
    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // token0
    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // token1
    uint256 usdcAmount = 90310804280;
    uint256 wethAmount = 24435378431291761028;
    address tester = 0x77756A696e7a686f75406C6976652e636F6D0000;
    SovereignPoolAdapter adapter;

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
        address nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        string memory tokenInSymbol = "NativeToken";
        string memory tokenOutSymbol = "NativeToken";
        uint256 inBefore = address(account).balance;
        uint256 outBefore = address(account).balance;

        if (tokenIn != nativeToken) {
            tokenInSymbol = IERC20(tokenIn).symbol();
            inBefore = IERC20(tokenIn).balanceOf(account);
        }

        if (tokenOut != nativeToken) {
            tokenOutSymbol = IERC20(tokenOut).symbol();
            outBefore = IERC20(tokenOut).balanceOf(account);
        }

        _;

        uint256 inAmount = tokenIn == nativeToken
            ? inBefore - address(account).balance
            : inBefore - IERC20(tokenIn).balanceOf(account);

        uint256 outAmount = tokenOut == nativeToken
            ? address(account).balance - outBefore
            : IERC20(tokenOut).balanceOf(account) - outBefore;

        string memory fmtStr = string(
            abi.encodePacked(
                "Swapped [%s] ",
                tokenInSymbol,
                " for [%s] ",
                tokenOutSymbol
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
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), blkHeight);
        adapter = new SovereignPoolAdapter();
        _fundTesterAndApprove(usdc, usdcAmount, weth, wethAmount);
    }

    function _getMoreInfo(
        address fromToken,
        address toToken
    ) private pure returns (bytes memory moreInfo) {
        moreInfo = abi.encode(fromToken, toToken);
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

    function test_weth_2_usdc()
        public
        user(tester)
        swapLog(tester, weth, usdc, wethAmount, 0)
    {
        //price reference: https://etherscan.io/tx/0x4afdda079b700741e28163def7648d030d4d82820c8d2243736b19a88b9f1464
        //the in / out amount does not exactly match as the above txn uses the private fee module
        _execSwap(weth, usdc, wethAmount);
    }

    function test_usdc_2_weth()
        public
        user(tester)
        swapLog(tester, usdc, weth, usdcAmount, 0)
    {
        _execSwap(usdc, weth, usdcAmount);
    }
}
