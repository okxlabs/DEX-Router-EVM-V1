// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/SolidlyAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract Velocimeter is Test {
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;
    address newImpl = 0xFA574f8B3152504E391E53FfF6e55E3Ee56e0889;

    address wCanto = 0x826551890Dc65655a0Aceca109aB11AbDbD7a07B; //token0
    address sCanto = 0x9F823D534954Fc119E31257b3dDBa0Db9E2Ff4ed; // token1
    address wCanto_sCanto = 0xe506707dF5fE9b2F6c0Bd6C5039fc542Af1eeB50;

    address bob = vm.rememberKey(1);

    SolidlyAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("CANTO_RPC_URL"));
        adapter = new SolidlyAdapter();
        require(newImpl.code.length > 0, "not work");
        vm.store(
            0x6b2C0c7be2048Daa9b5527982C29f48062B34D58,
            0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
            bytes32(uint256(uint160(newImpl)))
        );
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("wCanto balance before", IERC20(wCanto).balanceOf(address(_user)));
        console2.log("sCanto balance before", IERC20(sCanto).balanceOf(address(_user)));
        _;
        console2.log("wCanto balance after", IERC20(wCanto).balanceOf(address(_user)));
        console2.log("sCanto balance after", IERC20(sCanto).balanceOf(address(_user)));
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_swapWCantotoSCanto() public user(bob) tokenBalance(bob) {
        deal(wCanto, bob, 1 * 10 ** 18);
        IERC20(wCanto).approve(tokenApprove, 1 * 10 ** 18);

        uint256 amount = IERC20(wCanto).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(wCanto)));
        swapInfo.baseRequest.toToken = sCanto;
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
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(wCanto_sCanto);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] =
            uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(wCanto_sCanto))));
        swapInfo.batches[0][0].extraData = new bytes[](1); //extradata is 0x
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(wCanto)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }
}
