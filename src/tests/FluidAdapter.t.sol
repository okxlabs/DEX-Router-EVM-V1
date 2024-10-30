// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/FluidAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

/// @title FluidAdapterTest
/// @notice Do the usability test of FluidAdapter on Eth
/// @dev Explain to a developer any extra details

contract FluidAdapterTest is Test {
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

    DexRouter dexRouter =
        DexRouter(payable(0x7D0CcAa3Fac1e5A943c5168b6CEd828691b46B36));

    address wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address user = 0xa9BB7e640FF985376e67bbb5843bF9a63a2fBa02;
    address pool = 0x085B07A30381F3Cc5A4250e10E4379d465b770ac;

    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    FluidAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        adapter = new FluidAdapter(WETH);
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    // function test_swapWstETHtoETHFluid() public {
    //     vm.startPrank(user);
    //     deal(wstETH, user, 1 * 10 ** 18);
    //     console2.log("wstETH balance before", IERC20(wstETH).balanceOf(address(user)));

    //     SafeERC20.safeApprove(IERC20(wstETH), tokenApprove, 1 * 10 ** 18);

    //     uint256 amount = 1 * 10 ** 18;
    //     SwapInfo memory swapInfo;
    //     swapInfo.baseRequest.fromToken = uint256(uint160(address(wstETH)));
    //     swapInfo.baseRequest.toToken = ETH;
    //     swapInfo.baseRequest.fromTokenAmount = amount;
    //     swapInfo.baseRequest.minReturnAmount = 0;
    //     swapInfo.baseRequest.deadLine = block.timestamp;

    //     swapInfo.batchesAmount = new uint256[](1);
    //     swapInfo.batchesAmount[0] = amount;

    //     swapInfo.batches = new DexRouter.RouterPath[][](1);
    //     swapInfo.batches[0] = new DexRouter.RouterPath[](1);
    //     swapInfo.batches[0][0].mixAdapters = new address[](1);
    //     swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
    //     swapInfo.batches[0][0].assetTo = new address[](1);
    //     // direct interaction with vault
    //     swapInfo.batches[0][0].assetTo[0] = address(adapter);
    //     swapInfo.batches[0][0].rawData = new uint256[](1);
    //     swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(false, uint88(10000), address(pool))));
    //     swapInfo.batches[0][0].extraData = new bytes[](1);
    //     swapInfo.batches[0][0].extraData[0] = abi.encode(wstETH, WETH);
    //     swapInfo.batches[0][0].fromToken = uint256(uint160(address(wstETH)));

    //     swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

    //     dexRouter.smartSwapByOrderId(
    //         swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
    //     );
    // }

    function test_swapUSDCtoUSDTFluid() public {
        vm.startPrank(user);
        deal(USDC, user, 1 * 10 ** 6);
        console2.log(
            "USDC balance before",
            IERC20(USDC).balanceOf(address(user))
        );

        SafeERC20.safeApprove(IERC20(USDC), tokenApprove, 1 * 10 ** 6);

        uint256 amount = 1 * 10 ** 6;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC)));
        swapInfo.baseRequest.toToken = USDT;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with vault
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(false, uint88(10000), address(pool)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDC, USDT);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log(
            "USDT balance after",
            IERC20(USDT).balanceOf(address(user))
        );
    }
    function test_swapUSDTtoUSDCFluid() public {
        vm.startPrank(user);
        deal(USDT, user, 1 * 10 ** 6);
        console2.log(
            "USDT balance before",
            IERC20(USDT).balanceOf(address(user))
        );

        SafeERC20.safeApprove(IERC20(USDT), tokenApprove, 1 * 10 ** 6);

        uint256 amount = 1 * 10 ** 6;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDT)));
        swapInfo.baseRequest.toToken = USDC;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with vault
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(false, uint88(10000), address(pool)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDT, USDC);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDT)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log(
            "USDC balance after",
            IERC20(USDC).balanceOf(address(user))
        );
    }
}
