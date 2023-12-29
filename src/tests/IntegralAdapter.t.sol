// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/test.sol";
import "@dex/adapter/IntegralAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract IntegralTest is Test {

    address bob = vm.rememberKey(1);

    function setUp() public {

    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    // modifier tokenBalance(address _user) {
    //     console2.log("USDC balance before", IERC20(USDC).balanceOf(address(_user)));
    //     console2.log("USDT balance before", IERC20(USDT).balanceOf(address(_user)));
    //     _;
    //     console2.log("USDC balance after", IERC20(USDC).balanceOf(address(_user)));
    //     console2.log("USDT balance after", IERC20(USDT).balanceOf(address(_user)));
    // }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_arb() public user(bob) {
        
        DexRouter dexRouter = DexRouter(payable(0xf332761c673b59B21fF6dfa8adA44d78c12dEF09));
        address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;

        //swapUSDCetoWETH
        address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        address USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        address USDCe_WETH = 0x4BCa34ad27Df83566016B55c60Dd80a9eB14913b;

        vm.createSelectFork(vm.envString("ARB_RPC_URL"), 155470786);
        address TWAPRELAY_ADDRESS_ARB = 0x3c6951FDB433b5b8442e7aa126D50fBFB54b5f42;
        IntegralAdapter adapter = new IntegralAdapter(TWAPRELAY_ADDRESS_ARB);
        
        deal(USDCe, bob, 10 * 10 ** 6);
        IERC20(USDCe).approve(tokenApprove, 10 * 10 ** 6);

        uint256 amount = IERC20(USDCe).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDCe)));
        swapInfo.baseRequest.toToken = WETH;
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
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(USDCe_WETH))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDCe, WETH, uint256(0), block.timestamp);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDCe)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("USDCe balance before", IERC20(USDCe).balanceOf(address(bob)));
        console2.log("WETH balance before", IERC20(WETH).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("USDCe balance after", IERC20(USDCe).balanceOf(address(bob)));
        console2.log("WETH balance after", IERC20(WETH).balanceOf(address(bob)));
    }



    // function test_eth() public user(bob) tokenBalance(bob) {
        
    //     DexRouter dexRouter = DexRouter(payable(0x3b3ae790Df4F312e745D270119c6052904FB6790));
    //     address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    // }

}
