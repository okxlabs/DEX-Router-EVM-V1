// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/CompoundV2Adapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract CantoLending is Test {
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address wCanto = 0x826551890Dc65655a0Aceca109aB11AbDbD7a07B; //token0
    address cCanto = 0xB65Ec550ff356EcA6150F733bA9B954b2e0Ca488; // cToken

    address bob = vm.rememberKey(1);
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    CompoundAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("CANTO_RPC_URL"));
        adapter = new CompoundAdapter(wCanto);
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("wCanto balance before", IERC20(wCanto).balanceOf(address(_user)));
        console2.log("cCanto balance before", IERC20(cCanto).balanceOf(address(_user)));
        _;
        console2.log("wCanto balance after", IERC20(wCanto).balanceOf(address(_user)));
        console2.log("cCanto balance after", IERC20(cCanto).balanceOf(address(_user)));
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_swapWCantotocCanto() public user(bob) tokenBalance(bob) {
        deal(wCanto, bob, 1 * 10 ** 18);
        IERC20(wCanto).approve(tokenApprove, 1 * 10 ** 18);

        uint256 amount = IERC20(wCanto).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(wCanto)));
        swapInfo.baseRequest.toToken = cCanto;
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
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1); //extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(ETH_ADDRESS, cCanto, true);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(wCanto)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }
}
