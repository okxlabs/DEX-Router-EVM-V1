// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/FxAdapter.sol";
import "@dex/interfaces/ILidoVault.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract FxAdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0xF3dE3C0d654FDa23daD170f0f320a92172509127));
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

    address FETH = 0x53805A76E1f5ebbFE7115F16f9c87C2f7e633726;
    address XETH = 0xe063F04f280c60aECa68b38341C2eEcBeC703ae2;
    address STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    
    address bob = vm.rememberKey(1);

    FxAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 18539320);
        adapter = new FxAdapter();
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("FETH balance before", IERC20(FETH).balanceOf(address(_user)));
        console2.log("XETH balance before", IERC20(XETH).balanceOf(address(_user)));
        console2.log("STETH balance before", IERC20(STETH).balanceOf(address(_user)));
        _;
        console2.log("FETH balance after", IERC20(FETH).balanceOf(address(_user)));
        console2.log("XETH balance after", IERC20(XETH).balanceOf(address(_user)));
        console2.log("STETH balance after", IERC20(STETH).balanceOf(address(_user)));
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_mintFeth() public user(bob) tokenBalance(bob) {
        vm.deal(bob, 1 ether);
        ILidoVault(STETH).submit{value: 0.2 ether}(address(0));
        IERC20(STETH).approve(tokenApprove, 0.1 ether);

        uint256 amount = 0.1 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(STETH)));
        swapInfo.baseRequest.toToken = FETH;
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
        //  interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));//0 address to save gas
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(false, true);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(STETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_mintXeth() public user(bob) tokenBalance(bob) {
        vm.deal(bob, 1 ether);
        ILidoVault(STETH).submit{value: 0.2 ether}(address(0));
        IERC20(STETH).approve(tokenApprove, 0.1 ether);

        uint256 amount = 0.1 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(STETH)));
        swapInfo.baseRequest.toToken = XETH;
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
        //  interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));//0 address to save gas
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(true, true);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(STETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_redeemFeth() public user(bob) tokenBalance(bob) {
        vm.deal(bob, 1 ether);
        deal(FETH, bob, 0.1 ether);
        IERC20(FETH).approve(tokenApprove, 0.1 ether);

        uint256 amount = IERC20(FETH).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(FETH)));
        swapInfo.baseRequest.toToken = STETH;
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
        //  interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));//0 address to save gas
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(false, false);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(FETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_redeemXeth() public user(bob) tokenBalance(bob) {
        vm.deal(bob, 1 ether);
        deal(XETH, bob, 0.1 ether);
        IERC20(XETH).approve(tokenApprove, 0.1 ether);

        uint256 amount = IERC20(XETH).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(XETH)));
        swapInfo.baseRequest.toToken = STETH;
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
        //  interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));//0 address to save gas
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(true, false);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(XETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }
}
