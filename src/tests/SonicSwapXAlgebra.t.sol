pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/AlgebraAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract SonicSwapXAlgebraTest is Test {
    DexRouter dexRouter =
        DexRouter(payable(0x4Efa4b8545a3a77D80Da3ECC8F81EdB1a4bda783));
    address tokenApprove = 0xD321ab5589d3E8FA5Df985ccFEf625022E2DD910;

    address S = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address stS = 0xE5DA20F15420aD15DE0fa650600aFc998bbE3955;
    address WS_stS = 0xD760791B29e7894FB827A94Ca433254bb5aFB653;

    address arnaud = vm.rememberKey(1);

    AlgebraAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("SONIC_RPC_URL"), 12803096);
        adapter = new AlgebraAdapter(payable(WS)); // local deployed adapter
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        console2.log("User:", _user);
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

    function test_sonicSwapXAlgebra_swapWS2stS_adapter() public {
        deal(WS, address(this), 1 ether);
        console2.log("WS beforeswap balance", IERC20(WS).balanceOf(address(this)));
        console2.log("stS beforeswap balance", IERC20(stS).balanceOf(address(this)));
        IERC20(WS).transfer(address(adapter), 1 ether);
        adapter.sellBase(address(this), WS_stS, abi.encode(0, abi.encode(WS, stS)));
        console2.log("WS afterswap  balance", IERC20(WS).balanceOf(address(this)));
        console2.log("stS afterswap  balance", IERC20(stS).balanceOf(address(this)));
    }

    function test_sonicSwapXAlgebra_swapWS2stS_dexRouter() public user(arnaud) {
        deal(WS, arnaud, 1 ether);
        IERC20(WS).approve(tokenApprove, 1 ether);

        console2.log(
            "WS balance before",
            IERC20(WS).balanceOf(address(arnaud))
        );
        console2.log(
            "stS balance before",
            IERC20(stS).balanceOf(address(arnaud))
        );

        uint256 amount = IERC20(WS).balanceOf(address(arnaud));
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WS)));
        swapInfo.baseRequest.toToken = stS;
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
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WS_stS))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(WS, stS);
        swapInfo.batches[0][0].extraData[0] = abi.encode(sqrtX96, data);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WS)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        console2.log(
            "WS balance after",
            IERC20(WS).balanceOf(address(arnaud))
        );  
        console2.log(
            "stS balance after",
            IERC20(stS).balanceOf(address(arnaud))
        );
    }

    function test_sonicSwapXAlgebra_swapS2stS_dexRouter() public user(arnaud) {
        deal(arnaud, 1 ether);

        console2.log(
            "S balance before",
            arnaud.balance
        );
        console2.log(
            "WS balance before",
            IERC20(WS).balanceOf(address(arnaud))
        );
        console2.log(
            "stS balance before",
            IERC20(stS).balanceOf(address(arnaud))
        );

        uint256 amount = 1 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(S)));
        swapInfo.baseRequest.toToken = stS;
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
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WS_stS))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(WS, stS);
        swapInfo.batches[0][0].extraData[0] = abi.encode(sqrtX96, data);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WS)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId{value: 1 ether}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        console2.log(
            "S balance after",
            arnaud.balance
        );
        console2.log(
            "WS balance after",
            IERC20(WS).balanceOf(address(arnaud))
        );  
        console2.log(
            "stS balance after",
            IERC20(stS).balanceOf(address(arnaud))
        );
    }

    function test_sonicSwapXAlgebra_swapstS2S_dexRouter() public user(arnaud) {
        deal(stS, arnaud, 1 ether);
        IERC20(stS).approve(tokenApprove, 1 ether);

        console2.log(
            "S balance before",
            arnaud.balance
        );
        console2.log(
            "WS balance before",
            IERC20(WS).balanceOf(address(arnaud))
        );
        console2.log(
            "stS balance before",
            IERC20(stS).balanceOf(address(arnaud))
        );

        uint256 amount = 1 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(stS)));
        swapInfo.baseRequest.toToken = S;
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
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WS_stS))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(stS, WS);
        swapInfo.batches[0][0].extraData[0] = abi.encode(sqrtX96, data);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(stS)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        console2.log(
            "S balance after",
            arnaud.balance
        );
        console2.log(
            "WS balance after",
            IERC20(WS).balanceOf(address(arnaud))
        );  
        console2.log(
            "stS balance after",
            IERC20(stS).balanceOf(address(arnaud))
        );
    }
}
