// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/test.sol";
import "@dex/adapter/XdockAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

// Xdock internal trading
contract XdockAdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x69C236E021F5775B0D0328ded5EaC708E3B869DF));
    address tokenApprove = 0x8b773D83bc66Be128c60e07E17C8901f7a64F000;
    address tokenLaunchFactory = 0xe6A5f4b8257BbAd4F033D3831ebF23E0F833961F;
    address constant WOKB = 0xe538905cf8410324e03A5A23C1c177a474D59b2b;
    address constant OKB = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address amy = vm.rememberKey(1);
    XdockAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("XLAYER_RPC_URL"));
        adapter = new XdockAdapter(tokenLaunchFactory, WOKB);
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

    function test_buy_meme() public user(amy) {
        address memeToken = 0x26A406f6755d87414dC474e9472ED3917835a7B4;
        uint256 amount = 1 * 10 ** 18;

        deal(amy, amount);

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)));
        swapInfo.baseRequest.toToken = memeToken;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        // TradeInfo: fundAddress, tokenAddress, buyMeme, sellMemeAmount, sellCommissionRate1, sellCommissionReceiver1, sellCommissionRate2, sellCommissionReceiver2, minReturnAmount
        swapInfo.batches[0][0].extraData[0] = abi.encode(
            WOKB,           // fundAddress
            memeToken,      // tokenAddress
            true,           // buyMeme
            0,              // sellMemeAmount (not used for buy)
            0,              // sellCommissionRate1
            address(0),     // sellCommissionReceiver1
            0,              // sellCommissionRate2
            address(0),     // sellCommissionReceiver2
            1               // minReturnAmount
        );
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WOKB)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("ETH balance before", address(amy).balance);
        console2.log("memeToken balance before", IERC20(memeToken).balanceOf(address(amy)));

        dexRouter.smartSwapByOrderId{value: amount}(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("ETH balance after", address(amy).balance);
        console2.log("memeToken balance after", IERC20(memeToken).balanceOf(address(amy)));
    }

    function test_sell_meme() public user(amy) {
        address memeToken = 0x26A406f6755d87414dC474e9472ED3917835a7B4;
        uint256 amount = 10000 * 10 ** 18;

        deal(memeToken, amy, amount);
        IERC20(memeToken).approve(tokenLaunchFactory, amount);

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(memeToken)));
        swapInfo.baseRequest.toToken = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        swapInfo.baseRequest.fromTokenAmount = 1;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = 0;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);

        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        // TradeInfo: fundAddress, tokenAddress, buyMeme, sellMemeAmount, sellCommissionRate1, sellCommissionReceiver1, sellCommissionRate2, sellCommissionReceiver2, minReturnAmount
        swapInfo.batches[0][0].extraData[0] = abi.encode(
            WOKB,           // fundAddress
            memeToken,      // tokenAddress
            false,          // buyMeme (selling)
            amount,         // sellMemeAmount
            0,              // sellCommissionRate1
            address(0),     // sellCommissionReceiver1
            0,              // sellCommissionRate2
            address(0),     // sellCommissionReceiver2
            1               // minReturnAmount
        );
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(memeToken)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("ETH balance before", address(amy).balance);
        console2.log("memeToken balance before", IERC20(memeToken).balanceOf(address(amy)));

        IERC20(memeToken).transfer(address(adapter), amount);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("ETH balance after", address(amy).balance);
        console2.log("memeToken balance after", IERC20(memeToken).balanceOf(address(amy)));
    }
}
