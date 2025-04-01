pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/adapter/SolidlyseriesAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract SonicEqualizerExchange is Test {
    DexRouter dexRouter = DexRouter(payable(0x4Efa4b8545a3a77D80Da3ECC8F81EdB1a4bda783));
    address tokenApprove = 0xD321ab5589d3E8FA5Df985ccFEf625022E2DD910;
    address S = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address stS = 0xE5DA20F15420aD15DE0fa650600aFc998bbE3955;
    address WSstS = 0xB75C9073ea00AbDa9ff420b5Ae46fEe248993380;

    address arnaud = vm.rememberKey(1);

    SolidlyseriesAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("SONIC_RPC_URL"), 11370768);
        adapter = SolidlyseriesAdapter(payable(0x05A4D69B7e05Fb3C8904ea5158Bd2b7407e2F8e2));
        deal(WS, address(this), 1 * 10 ** 18);
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

    function test_WS2stS_Adapter() public {
        console2.log("WS balance before swap", IERC20(WS).balanceOf(address(this)));
        console2.log("stS balance before swap", IERC20(stS).balanceOf(address(this)));
        IERC20(WS).transfer(WSstS, 1 * 10 ** 17);
        bytes memory moreInfo = "0x";
        adapter.sellBase(address(this), WSstS, moreInfo);
        console2.log("WS balance after swap", IERC20(WS).balanceOf(address(this)));
        console2.log("stS balance after swap", IERC20(stS).balanceOf(address(this)));
    }

    function test_WS2stS_DexRouter() user(arnaud) public {
        deal(WS, arnaud, 1 * 10 ** 18);
        IERC20(WS).approve(tokenApprove, 1 * 10 ** 18);

        console2.log(
            "WS balance before swap",
            IERC20(WS).balanceOf(address(arnaud))
        );
        console2.log(
            "stS balance before swap",
            IERC20(stS).balanceOf(address(arnaud))
        );

        uint256 amount = 0.1 ether;
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
        swapInfo.batches[0][0].assetTo[0] = address(WSstS);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WSstS))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
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
            "WS balance after swap",
            IERC20(WS).balanceOf(address(arnaud))
        );
        console2.log(
            "stS balance after swap",
            IERC20(stS).balanceOf(address(arnaud))
        );
    }

    function test_S2stS_DexRouter() user(arnaud) public {
        deal(arnaud, 1 ether);

        console2.log(
            "S balance before swap",
            arnaud.balance
        );
        console2.log(
            "stS balance before swap",
            IERC20(stS).balanceOf(address(arnaud))
        );

        uint256 amount = 0.1 ether;
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
        swapInfo.batches[0][0].assetTo[0] = address(WSstS);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(false, uint88(10000), address(WSstS)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WS)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId{value: 0.1 ether}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        console2.log(
            "S balance after swap",
            arnaud.balance
        );
        console2.log(
            "stS balance after swap",
            IERC20(stS).balanceOf(address(arnaud))
        );
    }

    function test_stS2S_DexRouter() user(arnaud) public {
        deal(stS, arnaud, 1 * 10 ** 18);
        IERC20(stS).approve(tokenApprove, 1 * 10 ** 18);

        console2.log(
            "S balance before swap",
            arnaud.balance
        );
        console2.log(
            "stS balance before swap",
            IERC20(stS).balanceOf(address(arnaud))
        );

        uint256 amount = 0.1 ether;
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
        swapInfo.batches[0][0].assetTo[0] = address(WSstS);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(WSstS)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
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
            "S balance after swap",
            arnaud.balance
        );
        console2.log(
            "stS balance after swap",
            IERC20(stS).balanceOf(address(arnaud))
        );
    }    
}