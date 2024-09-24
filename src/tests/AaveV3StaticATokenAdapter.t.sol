// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/AaveV3StaticATokenAdapter.sol";

interface IERC4626 {
    function convertToShares(
        uint256 assets
    ) external view returns (uint256 shares);

    function convertToAssets(
        uint256 shares
    ) external view returns (uint256 assets);
}

contract AaveV3StaticATokenAdapterTest is Test {
    using SafeERC20 for IERC20;
    AaveV3StaticATokenAdapter adapter;

    address stataEthUSDT = 0x862c57d48becB45583AEbA3f489696D22466Ca1b;
    address aEthUSDT = 0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a;
    address ethUSDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address tester = 0xBeFF8DAe9f46CeBB2cEBd5f9274C67662C62A196;
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

    address stataEthUSDTFunder = 0xB8d9b1EC1c1F8Bea7fB10450198c0B47D50c96b7;
    address aEthUSDTFunder = 0x1FFa4239f3622F455738d9648b9c48553D67343D;
    address ethUSDTFunder = 0x3c1727C283370e476a63768C7cAb843B8bd63130;

    DexRouter dexRouter =
        DexRouter(payable(0x3b3ae790Df4F312e745D270119c6052904FB6790));

    uint256 swapAmount = 1000000;
    address pool = stataEthUSDT;

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    struct SwapInfo {
        uint orderId;
        DexRouter.BaseRequest baseRequest;
        uint[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20775914);
        adapter = new AaveV3StaticATokenAdapter();
        _fundTesterAndApprove(stataEthUSDTFunder, swapAmount, stataEthUSDT);
        _fundTesterAndApprove(aEthUSDTFunder, swapAmount, aEthUSDT);
        _fundTesterAndApprove(ethUSDTFunder, swapAmount, ethUSDT);
    }

    function _fundTesterAndApprove(
        address funder,
        uint amount,
        address token
    ) private {
        // fund tester and approve allowance to tokenApprove
        vm.startPrank(funder);
        IERC20(token).safeTransfer(tester, amount);
        vm.stopPrank();

        vm.startPrank(tester);
        IERC20(token).safeApprove(tokenApprove, amount);
        vm.stopPrank();
    }

    function _getSwapInfo(
        address fromToken,
        address toToken,
        uint256 amount
    ) private view returns (SwapInfo memory) {
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

        return swapInfo;
    }

    function test_stataEthUSDT_2_ethUSDT() public user(tester) {
        uint256 stataEthUSDT_before = IERC20(stataEthUSDT).balanceOf(tester);
        uint256 ethUSDT_before = IERC20(ethUSDT).balanceOf(tester);

        uint256 expectedAmountOut = IERC4626(pool).convertToAssets(swapAmount);

        SwapInfo memory swapInfo = _getSwapInfo(
            stataEthUSDT,
            ethUSDT,
            swapAmount
        );

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        uint256 stataEthUSDT_after = IERC20(stataEthUSDT).balanceOf(tester);
        uint256 ethUSDT_after = IERC20(ethUSDT).balanceOf(tester);

        assertEq(stataEthUSDT_after, stataEthUSDT_before - swapAmount);
        assertEq(ethUSDT_after, ethUSDT_before + expectedAmountOut);

        console2.log(
            "Swap from stataEthUSDT[%s] to ethUSDT[%s]",
            swapAmount,
            expectedAmountOut
        );
    }

    function test_stataEthUSDT_2_aEthUSDT() public user(tester) {
        uint256 stataEthUSDT_before = IERC20(stataEthUSDT).balanceOf(tester);
        uint256 aEthUSDT_before = IERC20(aEthUSDT).balanceOf(tester);

        uint256 expectedAmountOut = IERC4626(pool).convertToAssets(swapAmount);

        SwapInfo memory swapInfo = _getSwapInfo(
            stataEthUSDT,
            aEthUSDT,
            swapAmount
        );

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        uint256 stataEthUSDT_after = IERC20(stataEthUSDT).balanceOf(tester);
        uint256 aEthUSDT_after = IERC20(aEthUSDT).balanceOf(tester);

        assertEq(stataEthUSDT_after, stataEthUSDT_before - swapAmount);
        assertEq(aEthUSDT_after, aEthUSDT_before + expectedAmountOut);

        console2.log(
            "Swap from stataEthUSDT[%s] to aEthUSDT[%s]",
            swapAmount,
            expectedAmountOut
        );
    }

    function test_ethUSDT_2_stataEthUSDT() public user(tester) {
        uint256 ethUSDT_before = IERC20(ethUSDT).balanceOf(tester);
        uint256 stataEthUSDT_before = IERC20(stataEthUSDT).balanceOf(tester);

        uint256 expectedAmountOut = IERC4626(pool).convertToShares(swapAmount);

        SwapInfo memory swapInfo = _getSwapInfo(
            ethUSDT,
            stataEthUSDT,
            swapAmount
        );

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        uint256 ethUSDT_after = IERC20(ethUSDT).balanceOf(tester);
        uint256 stataEthUSDT_after = IERC20(stataEthUSDT).balanceOf(tester);

        assertEq(stataEthUSDT_after, stataEthUSDT_before + expectedAmountOut);
        assertEq(ethUSDT_after, ethUSDT_before - swapAmount);

        console2.log(
            "Swap from ethUSDT[%s] to stataEthUSDT[%s]",
            swapAmount,
            expectedAmountOut
        );
    }

    function test_aEthUSDT_2_stataEthUSDT() public user(tester) {
        uint256 aEthUSDT_before = IERC20(aEthUSDT).balanceOf(tester);
        uint256 stataEthUSDT_before = IERC20(stataEthUSDT).balanceOf(tester);

        uint256 expectedAmountOut = IERC4626(pool).convertToShares(swapAmount);

        SwapInfo memory swapInfo = _getSwapInfo(
            aEthUSDT,
            stataEthUSDT,
            swapAmount
        );

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        uint256 aEthUSDT_after = IERC20(aEthUSDT).balanceOf(tester);
        uint256 stataEthUSDT_after = IERC20(stataEthUSDT).balanceOf(tester);

        assertEq(stataEthUSDT_after, stataEthUSDT_before + expectedAmountOut);
        assertEq(aEthUSDT_after, aEthUSDT_before - swapAmount);

        console2.log(
            "Swap from aEthUSDT[%s] to stataEthUSDT[%s]",
            swapAmount,
            expectedAmountOut
        );
    }
}
