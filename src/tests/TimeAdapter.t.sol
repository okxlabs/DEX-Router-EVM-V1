pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/TimeAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract TimeAdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x9333C74BDd1E118634fE5664ACA7a9710b108Bab));
    address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;
    address BSCUSD = 0x55d398326f99059fF775485246999027B3197955;//18
    address USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;//18
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;//18
    address TIME = 0x13460EAAeaDe9427957F26A570345490b5d7910F;

    address amy = vm.rememberKey(1);

    TimeAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        adapter = new TimeAdapter(TIME, BSCUSD, USDC, BUSD);
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

    function test_Buy() public user(amy) {
        deal(BUSD, amy, 1 ether);
        console2.log("BUSD balance before",IERC20(BUSD).balanceOf(address(amy)));
        console2.log("TIME balance before",IERC20(TIME).balanceOf(address(amy)));
        IERC20(BUSD).approve(tokenApprove, 1 ether);

        uint256 amount = IERC20(BUSD).balanceOf(amy);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(BUSD)));
        swapInfo.baseRequest.toToken = TIME;
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
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(TIME))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(address(BUSD), address(TIME));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(BUSD)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
        console2.log("BUSD balance after",IERC20(BUSD).balanceOf(address(amy)));
        console2.log("TIME balance after",IERC20(TIME).balanceOf(address(amy)));
    }

    function test_Sell() public user(amy) {
        deal(TIME, amy, 1 ether);
        console2.log("BUSD balance before",IERC20(BUSD).balanceOf(address(amy)));
        console2.log("TIME balance before",IERC20(TIME).balanceOf(address(amy)));
        IERC20(TIME).approve(tokenApprove, 1 ether);

        uint256 amount = IERC20(TIME).balanceOf(amy);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(TIME)));
        swapInfo.baseRequest.toToken = BUSD;
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
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(TIME))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(address(TIME), address(BUSD));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(TIME)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
        console2.log("BUSD balance after",IERC20(BUSD).balanceOf(address(amy)));
        console2.log("TIME balance after",IERC20(TIME).balanceOf(address(amy)));
    }
}
