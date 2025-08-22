// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/test.sol";
import "@dex/adapter/AspectaAdapter.sol";
import "@dex/interfaces/IAspectaKeyPool.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract AspectaAdapterTest is Test {
    DexRouter dexRouter =
        DexRouter(payable(0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4));

    address pool = 0x0834f67a5882feB21B310310b03D93bA9a17Adfd; // pool, also the Key token address
    address BNB = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address arnaud = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38); // DefaultSender

    AspectaAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 54313660);
        adapter = new AspectaAdapter(payable(WBNB)); // local deployed adapter
        adapter.setDexRouter(address(dexRouter), true);
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_aspectaAdapter() public user(arnaud) {
        deal(arnaud, 1 ether);

        // test buy
        console2.log("========== test buy by router ==========");
        console2.log("native balance before:", address(arnaud).balance);
        console2.log(
            "Key balance before:",
            IERC20(pool).balanceOf(address(arnaud))
        );

        uint256 payment = 0.01 ether;
        (uint256 amount, uint256 totalPriceWithFee) = IAspectaKeyPool(pool)
            .getPurchaseAmountByPayment(payment);
        console2.log("assumed payment:", payment);
        console2.log("estimated key amount of assumed payment:", amount);
        console2.log(
            "estimated actual payment with fee of assumed payment:",
            totalPriceWithFee
        );

        SwapInfo memory swapInfo1;
        swapInfo1.baseRequest.fromToken = uint256(uint160(address(BNB)));
        swapInfo1.baseRequest.toToken = pool;
        swapInfo1.baseRequest.fromTokenAmount = totalPriceWithFee;
        swapInfo1.baseRequest.minReturnAmount = 0;
        swapInfo1.baseRequest.deadLine = block.timestamp;

        swapInfo1.batchesAmount = new uint[](1);
        swapInfo1.batchesAmount[0] = totalPriceWithFee;

        swapInfo1.batches = new DexRouter.RouterPath[][](1);
        swapInfo1.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo1.batches[0][0].mixAdapters = new address[](1);
        swapInfo1.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo1.batches[0][0].assetTo = new address[](1);
        swapInfo1.batches[0][0].assetTo[0] = address(adapter);
        swapInfo1.batches[0][0].rawData = new uint[](1);
        swapInfo1.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(pool))) // false -> sellBase -> buy
        );
        swapInfo1.batches[0][0].extraData = new bytes[](1);
        swapInfo1.batches[0][0].extraData[0] = abi.encode(amount);
        swapInfo1.batches[0][0].fromToken = uint256(uint160(address(WBNB)));

        swapInfo1.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId{value: totalPriceWithFee}(
            swapInfo1.orderId,
            swapInfo1.baseRequest,
            swapInfo1.batchesAmount,
            swapInfo1.batches,
            swapInfo1.extraData
        );

        console2.log("native balance after buy:", address(arnaud).balance);
        console2.log(
            "Key balance after buy:",
            IERC20(pool).balanceOf(address(arnaud))
        );

        // test buy
        console2.log("========== test sell by router ==========");

        SwapInfo memory swapInfo2;
        swapInfo2.baseRequest.fromToken = uint256(uint160(address(pool)));
        swapInfo2.baseRequest.toToken = BNB;
        swapInfo2.baseRequest.fromTokenAmount = 1;
        swapInfo2.baseRequest.minReturnAmount = 0;
        swapInfo2.baseRequest.deadLine = block.timestamp;

        swapInfo2.batchesAmount = new uint[](1);
        swapInfo2.batchesAmount[0] = 0; // to avoid transfer key in claim, because the key is not transferable

        swapInfo2.batches = new DexRouter.RouterPath[][](1);
        swapInfo2.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo2.batches[0][0].mixAdapters = new address[](1);
        swapInfo2.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo2.batches[0][0].assetTo = new address[](1);
        swapInfo2.batches[0][0].assetTo[0] = address(adapter);
        swapInfo2.batches[0][0].rawData = new uint[](1);
        swapInfo2.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(pool))) // true -> sellQuote -> buy
        );
        swapInfo2.batches[0][0].extraData = new bytes[](1);
        swapInfo2.batches[0][0].extraData[0] = abi.encode(
            amount,
            0,
            0,
            address(0)
        );
        swapInfo2.batches[0][0].fromToken = uint256(uint160(address(pool)));

        swapInfo2.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo2.orderId,
            swapInfo2.baseRequest,
            swapInfo2.batchesAmount,
            swapInfo2.batches,
            swapInfo2.extraData
        );

        console2.log(
            "native balance after sell all keys:",
            address(arnaud).balance
        );
        console2.log(
            "Key balance after sell all keys:",
            IERC20(pool).balanceOf(address(arnaud))
        );
    }
    
    function test_buyByRouter() public user(arnaud) {
        deal(arnaud, 1 ether);

        uint256 payment = 0.01 ether;
        (uint256 expectedKeys, uint256 actualCost) = IAspectaKeyPool(pool)
            .getPurchaseAmountByPayment(payment);

        console2.log("native balance before buy:", address(arnaud).balance);
        console2.log(
            "Key balance before buy:",
            IERC20(pool).balanceOf(address(arnaud))
        );

        console2.log("expected keys:", expectedKeys);
        console2.log("actual cost:", actualCost);

        IAspectaKeyPool(pool).buyByRouter{value: actualCost}(
            expectedKeys,
            arnaud
        );

        console2.log("native balance after buy:", address(arnaud).balance);
        console2.log(
            "Key balance after buy:",
            IERC20(pool).balanceOf(address(arnaud))
        );

        // Assert have keys
        assertGt(
            IERC20(pool).balanceOf(address(arnaud)),
            0,
            "Should have keys"
        );
    }

    function test_sellByRouter() public user(arnaud) {
        deal(arnaud, 1 ether);

        uint256 payment = 0.01 ether;
        (uint256 expectedKeys, uint256 actualCost) = IAspectaKeyPool(pool)
            .getPurchaseAmountByPayment(payment);

        IAspectaKeyPool(pool).buyByRouter{value: actualCost}(
            expectedKeys,
            arnaud
        );

        uint256 keysBefore = IERC20(pool).balanceOf(arnaud);
        uint256 nativeBalanceBefore = arnaud.balance;

        console2.log("Keys before sell:", keysBefore);
        console2.log("Native balance before sell:", nativeBalanceBefore);

        uint256 sellPrice = IAspectaKeyPool(pool).getSellPrice(keysBefore);
        console2.log("Expected sell price:", sellPrice);

        uint256 minPrice = (sellPrice * 90) / 100;

        IAspectaKeyPool(pool).sellByRouter(keysBefore, minPrice);
    
        uint256 keysAfter = IERC20(pool).balanceOf(arnaud);
        uint256 nativeBalanceAfter = arnaud.balance;

        console2.log("Keys after sell:", keysAfter);
        console2.log("Native balance after sell:", nativeBalanceAfter);

        // Assert have no keys
        assertEq(keysAfter, 0, "Should have sold all keys");
        assertGt(
            nativeBalanceAfter,
            nativeBalanceBefore,
            "Should receive native tokens"
        );

        // Assert meet minimum price
        assertGe(
            nativeBalanceAfter - nativeBalanceBefore,
            minPrice,
            "Should meet minimum price"
        );
    }
}
