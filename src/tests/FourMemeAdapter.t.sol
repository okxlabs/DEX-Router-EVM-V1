// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/test.sol";
import "@dex/adapter/FourMemeAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract FourMemeTest is Test {

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

    function test_fourMeme_buy_native() public user(bob) {
        
        DexRouter dexRouter = DexRouter(payable(0xc44Ad35B5A41C428c0eAE842F20F84D1ff6ed917));
        address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;

        //swap bnb to memeToken
        address TOKENMANAGER2 = 0x5c952063c7fc8610FFDB798152D69F0B9550762b;
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        address fundToken = WBNB;
        address memeToken = 0xe52594beE022F03040cA041Ee3f62470CCE4034D;//name: bird2

        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 49700850);
        //https://bscscan.com/tx/0x95b0cf3dfe37a3fc77bdbbfec8be475b7ede8d4086a58d82fc6d068daac0c8bc
        
        FourMemeAdapter adapter = new FourMemeAdapter(WBNB, TOKENMANAGER2);
        
        deal(fundToken, bob, 1 * 10 ** 16);
        IERC20(fundToken).approve(tokenApprove, 1 * 10 ** 16);

        uint256 amount = IERC20(fundToken).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(fundToken)));
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
        swapInfo.batches[0][0].extraData[0] = abi.encode(fundToken, memeToken, true, uint256(0), uint256(0), address(0), uint256(0), address(0), uint256(0));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(fundToken)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("fundToken balance before", IERC20(fundToken).balanceOf(address(bob)));
        console2.log("memeToken balance before", IERC20(memeToken).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("fundToken balance after", IERC20(fundToken).balanceOf(address(bob)));
        console2.log("memeToken balance after", IERC20(memeToken).balanceOf(address(bob)));
    }

    function test_fourMeme_buy() public user(bob) {
        
        DexRouter dexRouter = DexRouter(payable(0xc44Ad35B5A41C428c0eAE842F20F84D1ff6ed917));
        address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;

        //swap usdt to memeToken
        address TOKENMANAGER2 = 0x5c952063c7fc8610FFDB798152D69F0B9550762b;
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        address USDT = 0x55d398326f99059fF775485246999027B3197955;
        address fundToken = USDT;
        address memeToken = 0xb6A303FAC827B37073C4Fb48Dc3cF25EBe7DF7F1;//name: a

        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 49700850);
        //https://bscscan.com/tx/0x6d302f1a2a71311f1daaec2f4e5ec0731f3a7389cdcf5fb5f34f089d3904ce2b
        
        FourMemeAdapter adapter = new FourMemeAdapter(WBNB, TOKENMANAGER2);
        
        deal(fundToken, bob, 6 * 10 ** 18);
        IERC20(fundToken).approve(tokenApprove, 6 * 10 ** 18);

        uint256 amount = IERC20(fundToken).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(fundToken)));
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
        swapInfo.batches[0][0].extraData[0] = abi.encode(fundToken, memeToken, true, uint256(0), uint256(0), address(0), uint256(0), address(0), uint256(0));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(fundToken)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("fundToken balance before", IERC20(fundToken).balanceOf(address(bob)));
        console2.log("memeToken balance before", IERC20(memeToken).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("fundToken balance after", IERC20(fundToken).balanceOf(address(bob)));
        console2.log("memeToken balance after", IERC20(memeToken).balanceOf(address(bob)));
    }

    function test_fourMeme_sell_native() public {
        address bob = tx.origin;
        
        vm.startPrank(bob);

        console2.log("address", address(this));
        console2.log("tx origin", tx.origin);
        console2.log("bob", bob);
        
        DexRouter dexRouter = DexRouter(payable(0xc44Ad35B5A41C428c0eAE842F20F84D1ff6ed917));
        address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;

        //swap bnb to memeToken
        address TOKENMANAGER2 = 0x5c952063c7fc8610FFDB798152D69F0B9550762b;
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        address fundToken = WBNB;
        address memeToken = 0xe52594beE022F03040cA041Ee3f62470CCE4034D;//name: bird2

        FourMemeAdapter.TradeInfo memory tradeInfo;
        tradeInfo.fundAddress = fundToken;
        tradeInfo.tokenAddress = memeToken;
        tradeInfo.buyMeme = false;
        tradeInfo.sellMemeAmount = 129 * 10 ** 18;
        tradeInfo.sellCommissionRate1 = 100;
        tradeInfo.sellCommissionRate2 = 100;
        tradeInfo.sellCommissionReceiver1 = vm.rememberKey(1111);
        tradeInfo.sellCommissionReceiver2 = vm.rememberKey(2222);
        tradeInfo.minReturnAmount = 0;

        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 49700850);
        
        FourMemeAdapter adapter = new FourMemeAdapter(WBNB, TOKENMANAGER2);
        
        deal(memeToken, bob, 129 * 10 ** 18);
        //IERC20(memeToken).approve(tokenApprove, 129 * 10 ** 18);
        IERC20(memeToken).approve(TOKENMANAGER2, 129 * 10 ** 18);

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(memeToken)));
        swapInfo.baseRequest.toToken = fundToken;
        swapInfo.baseRequest.fromTokenAmount = 1;//❗️不管都少数目，base request都传1
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = 0;//❗️不管都少数目，batchesAmount都传0，

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
        swapInfo.batches[0][0].extraData[0] = abi.encode(tradeInfo);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(memeToken)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        // console2.log("fundToken balance before", IERC20(fundToken).balanceOf(address(bob))); // WNATIVE balance keep same
        console2.log("ETH balance before", address(bob).balance);
        console2.log("memeToken balance before", IERC20(memeToken).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        // console2.log("fundToken balance after", IERC20(fundToken).balanceOf(address(bob)));
        console2.log("ETH balance after", address(bob).balance);
        console2.log("memeToken balance after", IERC20(memeToken).balanceOf(address(bob)));
        console2.log("commissionReceiver1 ETH balance", address(tradeInfo.sellCommissionReceiver1).balance);
        console2.log("commissionReceiver2 ETH balance", address(tradeInfo.sellCommissionReceiver2).balance);
    }

    function test_fourMeme_sell() public  {
        address bob = tx.origin;
        
        vm.startPrank(bob);

        console2.log("address", address(this));
        console2.log("tx origin", tx.origin);
        console2.log("bob", bob);

        DexRouter dexRouter = DexRouter(payable(0xc44Ad35B5A41C428c0eAE842F20F84D1ff6ed917));
        address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;

        //swap usdt to memeToken
        address TOKENMANAGER2 = 0x5c952063c7fc8610FFDB798152D69F0B9550762b;
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        address USDT = 0x55d398326f99059fF775485246999027B3197955;
        address fundToken = USDT;
        address memeToken = 0xb6A303FAC827B37073C4Fb48Dc3cF25EBe7DF7F1;//name: a

        FourMemeAdapter.TradeInfo memory tradeInfo;
        tradeInfo.fundAddress = fundToken;
        tradeInfo.tokenAddress = memeToken;
        tradeInfo.buyMeme = false;
        tradeInfo.sellMemeAmount = 1550234 * 10 ** 18;
        tradeInfo.sellCommissionRate1 = 100;
        tradeInfo.sellCommissionRate2 = 100;
        tradeInfo.sellCommissionReceiver1 = vm.rememberKey(1111);
        tradeInfo.sellCommissionReceiver2 = vm.rememberKey(2222);
        tradeInfo.minReturnAmount = 0;

        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 49700850);
        //25.05.15
        
        FourMemeAdapter adapter = new FourMemeAdapter(WBNB, TOKENMANAGER2);
        
        deal(memeToken, bob, 1550234 * 10 ** 18);
        //IERC20(memeToken).approve(tokenApprove, 1550234 * 10 ** 18);
        IERC20(memeToken).approve(TOKENMANAGER2, 1550234 * 10 ** 18);//不授权统一授权，授权项目方

        uint256 amount = IERC20(memeToken).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(memeToken)));
        swapInfo.baseRequest.toToken = fundToken;
        // swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.fromTokenAmount = 1;//❗️不管都少数目，base request都传1
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        //swapInfo.batchesAmount[0] = amount;
        swapInfo.batchesAmount[0] = 0;//❗️不管都少数目，batchesAmount都传0，

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);//因为fromTokenAmount是0所以不会有claim
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(tradeInfo);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(memeToken)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("fundToken balance before", IERC20(fundToken).balanceOf(address(bob)));
        console2.log("memeToken balance before", IERC20(memeToken).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("fundToken balance after", IERC20(fundToken).balanceOf(address(bob)));
        console2.log("memeToken balance after", IERC20(memeToken).balanceOf(address(bob)));
        console2.log("commissionReceiver1 fundToken balance", IERC20(fundToken).balanceOf(tradeInfo.sellCommissionReceiver1));
        console2.log("commissionReceiver2 fundToken balance", IERC20(fundToken).balanceOf(tradeInfo.sellCommissionReceiver2));

        vm.stopPrank();
    }

    function test_fourMeme_sell_with_dust() public  {
        address bob = tx.origin;
        
        vm.startPrank(bob);

        console2.log("address", address(this));
        console2.log("tx origin", tx.origin);
        console2.log("bob", bob);

        DexRouter dexRouter = DexRouter(payable(0xc44Ad35B5A41C428c0eAE842F20F84D1ff6ed917));
        address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;

        //swap usdt to memeToken
        address TOKENMANAGER2 = 0x5c952063c7fc8610FFDB798152D69F0B9550762b;
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        address USDT = 0x55d398326f99059fF775485246999027B3197955;
        address fundToken = USDT;
        address memeToken = 0xb6A303FAC827B37073C4Fb48Dc3cF25EBe7DF7F1;//name: a

        FourMemeAdapter.TradeInfo memory tradeInfo;
        tradeInfo.fundAddress = fundToken;
        tradeInfo.tokenAddress = memeToken;
        tradeInfo.buyMeme = false;
        tradeInfo.sellMemeAmount = 1550234 * 10 ** 18 + 1;
        tradeInfo.sellCommissionRate1 = 100;
        tradeInfo.sellCommissionRate2 = 100;
        tradeInfo.sellCommissionReceiver1 = vm.rememberKey(1111);
        tradeInfo.sellCommissionReceiver2 = vm.rememberKey(2222);
        tradeInfo.minReturnAmount = 0;

        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 49700850);
        //25.05.15
        
        FourMemeAdapter adapter = new FourMemeAdapter(WBNB, TOKENMANAGER2);
        
        deal(memeToken, bob, 1550234 * 10 ** 18 + 1);
        //IERC20(memeToken).approve(tokenApprove, 1550234 * 10 ** 18);
        IERC20(memeToken).approve(TOKENMANAGER2, 1550234 * 10 ** 18 + 1);//不授权统一授权，授权项目方

        uint256 amount = IERC20(memeToken).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(memeToken)));
        swapInfo.baseRequest.toToken = fundToken;
        // swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.fromTokenAmount = 1;//❗️不管都少数目，base request都传1
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        //swapInfo.batchesAmount[0] = amount;
        swapInfo.batchesAmount[0] = 0;//❗️不管都少数目，batchesAmount都传0，

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);//因为fromTokenAmount是0所以不会有claim
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(tradeInfo);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(memeToken)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("fundToken balance before", IERC20(fundToken).balanceOf(address(bob)));
        console2.log("memeToken balance before", IERC20(memeToken).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("fundToken balance after", IERC20(fundToken).balanceOf(address(bob)));
        console2.log("memeToken balance after", IERC20(memeToken).balanceOf(address(bob)));
        console2.log("commissionReceiver1 fundToken balance", IERC20(fundToken).balanceOf(tradeInfo.sellCommissionReceiver1));
        console2.log("commissionReceiver2 fundToken balance", IERC20(fundToken).balanceOf(tradeInfo.sellCommissionReceiver2));

        vm.stopPrank();
    }
}
