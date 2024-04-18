// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import "@dex/adapter/NetswapAdapterMetis.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/interfaces/IUnswapRouter02.sol";
import "@dex/interfaces/IUni.sol";
import "@dex/interfaces/IUniswapV2Factory.sol";

contract Deploy is Script {
    address ETH = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;
    address WETH = 0x75cb093E4D61d2A2e65D8e0BBb01DE8d89b53481;
    address USDC = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;
    address ETH_TOKEN_POOL = 0x5Ae3ee7fBB3Cb28C17e7ADc3a6Ae605ae2465091;

    address user = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    NetswapAdapter adapter;

    // function run() public {
    //     require(deployer == 0xc3A65A60073a1204bAb78fE5Bc01556A1Da0539F, "wrong deployer! change the private key");

    //     // deploy on Metis
    //     vm.createSelectFork("https://andromeda.metis.io/?owner=1088");
    //     vm.startBroadcast(deployer);

    //     console2.log("block.chainID", block.chainid);
    //     require(block.chainid == 1088 , "must be Metis");
      
    //     address adapter = address(new NetswapAdapter());
    //     console2.log("NetswapAdapter deployed on Metis: %s", adapter);

    //     vm.stopBroadcast();
    // }

    struct SmartSwapInfo {
        uint256 orderId;
        address receiver;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function run() public {
        // vm.createSelectFork("https://andromeda.metis.io/?owner=1088");
        vm.startBroadcast(user);
        adapter = NetswapAdapter(payable(0xFA574f8B3152504E391E53FfF6e55E3Ee56e0889));
        // console2.log("Balance before: ", IERC20(ETH).balanceOf(user), IERC20(USDC).balanceOf(user));

        SmartSwapInfo memory info;
        info.orderId = 0;
        info.receiver = user;
        info.baseRequest.fromToken = uint256(uint160(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
        info.baseRequest.toToken = USDC;
        info.baseRequest.fromTokenAmount = 1 * 10**15;
        info.baseRequest.minReturnAmount = 0;
        info.baseRequest.deadLine = type(uint256).max;
        info.batchesAmount = new uint256[](1);
        info.batchesAmount[0] = 1 * 10**15;
        info.batches = new DexRouter.RouterPath[][](1);
        info.batches[0] = new DexRouter.RouterPath[](1);
        info.batches[0][0].mixAdapters = new address[](1);
        info.batches[0][0].mixAdapters[0] = address(adapter);
        info.batches[0][0].assetTo = new address[](1);
        info.batches[0][0].assetTo[0] = address(adapter);
        info.batches[0][0].rawData = new uint256[](1);
        info.batches[0][0].rawData[0] =
            uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(ETH_TOKEN_POOL))));
        info.batches[0][0].extraData = new bytes[](1);
        info.batches[0][0].extraData[0] = abi.encode(30);
        info.batches[0][0].fromToken = uint256(uint160(WETH));
        info.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapTo{value: 1 * 10**15}(
            info.orderId, info.receiver, info.baseRequest, info.batchesAmount, info.batches, info.extraData
        );

        console2.log("Balance after: ", IERC20(ETH).balanceOf(user), IERC20(USDC).balanceOf(user));

        vm.stopBroadcast();
    }

    // function run() public {
    //     // USDC ---> Metis : [Success]Hash: 0xca2b9afbfcc608de6f60d7e71bc51988e4eb5913a8d0b266f26a747b058951fb
    //     // vm.createSelectFork("https://andromeda.metis.io/?owner=1088");
    //     vm.startBroadcast(user);
    //     adapter = NetswapAdapter(payable(0xFA574f8B3152504E391E53FfF6e55E3Ee56e0889));
    //     IERC20(USDC).approve(tokenApprove, 1 * 10 ** 6);
    //     console2.log("Balance before: ", IERC20(ETH).balanceOf(user), IERC20(USDC).balanceOf(user));

    //     SmartSwapInfo memory info;
    //     info.orderId = 0;
    //     info.receiver = user;
    //     info.baseRequest.fromToken = uint256(uint160(USDC));
    //     info.baseRequest.toToken = ETH;
    //     info.baseRequest.fromTokenAmount = 1 * 10**6;
    //     info.baseRequest.minReturnAmount = 0;
    //     info.baseRequest.deadLine = type(uint256).max;
    //     info.batchesAmount = new uint256[](1);
    //     info.batchesAmount[0] = 1 * 10**6;
    //     info.batches = new DexRouter.RouterPath[][](1);
    //     info.batches[0] = new DexRouter.RouterPath[](1);
    //     info.batches[0][0].mixAdapters = new address[](1);
    //     info.batches[0][0].mixAdapters[0] = address(adapter);
    //     info.batches[0][0].assetTo = new address[](1);
    //     info.batches[0][0].assetTo[0] = address(adapter);
    //     info.batches[0][0].rawData = new uint256[](1);
    //     info.batches[0][0].rawData[0] =
    //         uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(ETH_TOKEN_POOL))));
    //     info.batches[0][0].extraData = new bytes[](1);
    //     info.batches[0][0].extraData[0] = abi.encode(30);
    //     info.batches[0][0].fromToken = uint256(uint160(USDC));
    //     info.extraData = new PMMLib.PMMSwapRequest[](0);
    //     dexRouter.smartSwapTo(
    //         info.orderId, info.receiver, info.baseRequest, info.batchesAmount, info.batches, info.extraData
    //     );

    //     console2.log("Balance after: ", IERC20(ETH).balanceOf(user), IERC20(USDC).balanceOf(user));

    //     vm.stopBroadcast();
    // }

    // function run() public {
    //     vm.createSelectFork("https://andromeda.metis.io/?owner=1088");
    //     vm.startBroadcast(user);
    //     adapter = NetswapAdapter(payable(0xFA574f8B3152504E391E53FfF6e55E3Ee56e0889));

    //     console2.log("Balance before: ", IERC20(ETH).balanceOf(user), IERC20(USDC).balanceOf(user));

    //     bytes memory data =
    //         hex"b80c2f09000000000000000000000000000000000000000000000000002e2e4be901abc0000000000000000000000000bb06dca3ae6887fabf931640f67cab3e3a16f4dc000000000000000000000000096a84536ab84e68ee210561ffd3a038e79736f100000000000000000000000000000000000000000000000000000000000ffa58000000000000000000000000000000000000000000000000007c286e79a3351b00000000000000000000000000000000000000000000000000000000661b99960000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000005c0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000ffa580000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000bb06dca3ae6887fabf931640f67cab3e3a16f4dc0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000FA574f8B3152504E391E53FfF6e55E3Ee56e08890000000000000000000000000000000000000000000000000000000000000001000000000000000000000000FA574f8B3152504E391E53FfF6e55E3Ee56e088900000000000000000000000000000000000000000000000000000000000000010000000000000000000027108121113eb9952086dec3113690af0538bb5506fd000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016000000000000000000000000075cb093e4d61d2a2e65d8e0bbb01de8d89b534810000000000000000000000000000000000000000000000000000000000000001000000000000000000000000FA574f8B3152504E391E53FfF6e55E3Ee56e08890000000000000000000000000000000000000000000000000000000000000001000000000000000000000000FA574f8B3152504E391E53FfF6e55E3Ee56e0889000000000000000000000000000000000000000000000000000000000000000180000000000000000000271092372dc7425c4b6a05ff5aae791333de750ae9ed000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000000";
    //     (bool s,) = address(dexRouter).call(data);
    //     require(s, "not ok");

    //     console2.log("Balance after: ", IERC20(ETH).balanceOf(user), IERC20(USDC).balanceOf(user));

    //     vm.stopBroadcast();
    // }
}