// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/AngleAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

/// @title AngleAdapterTest
/// @notice Do the usability test of AngleAdapter on Eth
/// @dev Explain to a developer any extra details

contract AngleAdapterTest is Test {
    address USDA = 0x0000206329b97DB379d5E1Bf586BbDB969C63274;
    address EURA = 0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8;
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address USDA_USDC = 0x222222fD79264BBE280b4986F6FEfBC3524d0137;
    address EURA_BC3M = 0x00253582b2a3FE112feEC532221d9708c64cEFAb;
    address BC3M = 0x2F123cF3F37CE3328CC9B5b8415f9EC5109b45e7;

    DexRouter dexRouter = DexRouter(payable(0xF3dE3C0d654FDa23daD170f0f320a92172509127));

    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address user = 0xa9BB7e640FF985376e67bbb5843bF9a63a2fBa02;

    AngleAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20641855);
        adapter = new AngleAdapter();
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_swapUSDCtoUSDA() public {
        vm.startPrank(user);
        console2.log("USDC balance before", IERC20(USDC).balanceOf(address(user)));
        console2.log("USDA balance before", IERC20(USDA).balanceOf(address(user)));

        SafeERC20.safeApprove(IERC20(USDC),tokenApprove, 1 * 10 **6);

        uint256 amount = 1000000;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC)));
        swapInfo.baseRequest.toToken = USDA;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with vault
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(false, uint88(10000), address(USDA_USDC))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDC, USDA);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
        console2.log("USDC balance after", IERC20(USDC).balanceOf(address(user)));
        console2.log("USDA balance after", IERC20(USDA).balanceOf(address(user)));
    }

}
