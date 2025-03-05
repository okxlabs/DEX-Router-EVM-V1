pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/UniV3Adapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract SonicSpookySwapV3 is Test {
    DexRouter dexRouter = DexRouter(payable(0x4Efa4b8545a3a77D80Da3ECC8F81EdB1a4bda783));
    address tokenApprove = 0xD321ab5589d3E8FA5Df985ccFEf625022E2DD910;

    address S = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address USDC = 0x29219dd400f2Bf60E5a23d13Be72B486D4038894; // decimals: 6
    address WSUSDC = 0x216A86c8716Fad79E05D23b1622cA432A739582A; // WS<->USDC, V3

    address arnaud = vm.rememberKey(1);

    UniV3Adapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("SONIC_RPC_URL"), 11538784);
        adapter = UniV3Adapter(payable(0xF3C793B1821Bb1301F8f79E770Cbf8A7129DdAE2));
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


    function test_WS2USDC_Adapter() public {
        deal(WS, address(this), 1 ether);

        console2.log(
            "WS balance before",
            IERC20(WS).balanceOf(address(this))
        );
        console2.log(
            "USDC balance before",
            IERC20(USDC).balanceOf(address(this))
        );

        IERC20(WS).transfer(address(adapter), 0.1 ether);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(WS, USDC, uint24(3000));
        bytes memory moreInfo = abi.encode(sqrtX96, data);
        adapter.sellBase(address(this), WSUSDC, moreInfo);

        console2.log(
            "WS balance after",
            IERC20(WS).balanceOf(address(this))
        );
        console2.log(
            "USDC balance after",
            IERC20(USDC).balanceOf(address(this))
        );
    }

    function test_WS2USDC_DexRouter() public user(arnaud) {
        deal(WS, arnaud, 1 * 10 ** 18);
        IERC20(WS).approve(tokenApprove, 1 * 10 ** 18);

        console2.log(
            "WS balance before",
            IERC20(WS).balanceOf(address(arnaud))
        );
        console2.log(
            "USDC balance before",
            IERC20(USDC).balanceOf(address(arnaud))
        );

        uint256 amount = 0.1 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WS)));
        swapInfo.baseRequest.toToken = USDC;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WSUSDC))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(WS, USDC, uint24(3000));
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
            "USDC balance after",
            IERC20(USDC).balanceOf(address(arnaud))
        );
    }

    function test_S2USDC_DexRouter() public user(arnaud) {
        deal(arnaud, 1 ether);

        console2.log(
            "S balance before",
            arnaud.balance
        );
        console2.log(
            "USDC balance before",
            IERC20(USDC).balanceOf(address(arnaud))
        );

        uint256 amount = 0.1 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(S)));
        swapInfo.baseRequest.toToken = USDC;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WSUSDC))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(WS, USDC, uint24(3000));
        swapInfo.batches[0][0].extraData[0] = abi.encode(sqrtX96, data);
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
            "S balance after",
            arnaud.balance
        );
        console2.log(
            "USDC balance after",
            IERC20(USDC).balanceOf(address(arnaud))
        );
    }

    function test_USDC2S_DexRouter() public user(arnaud) {
        deal(USDC, arnaud, 10 * 10 ** 6);
        IERC20(USDC).approve(tokenApprove, 10 * 10 ** 6);

        console2.log(
            "S balance before",
            arnaud.balance
        );
        console2.log(
            "USDC balance before",
            IERC20(USDC).balanceOf(address(arnaud))
        );

        uint256 amount = 1 * 10 ** 6;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC)));
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(WSUSDC))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(USDC, WS, uint24(3000));
        swapInfo.batches[0][0].extraData[0] = abi.encode(sqrtX96, data);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

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
            "USDC balance after",
            IERC20(USDC).balanceOf(address(arnaud))
        );
    }
}