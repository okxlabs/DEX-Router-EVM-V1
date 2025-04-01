pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/SolidlyseriesAdapter.sol";
import "@dex/adapter/UniV3Adapter2.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract SonicShadowAdapterTest is Test {
    DexRouter dexRouter =
        DexRouter(payable(0x4Efa4b8545a3a77D80Da3ECC8F81EdB1a4bda783));
    address tokenApprove = 0xD321ab5589d3E8FA5Df985ccFEf625022E2DD910;

    address S = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address SHADOW = 0x3333b97138D4b086720b5aE8A7844b1345a33333;
    address USDC = 0x29219dd400f2Bf60E5a23d13Be72B486D4038894; // decimals: 6
    address WETH = 0x50c42dEAcD8Fc9773493ED674b675bE577f2634b;
    address USDT = 0x6047828dc181963ba44974801FF68e538dA5eaF9;
    address WS_SHADOW = 0xF19748a0E269c6965a84f8C98ca8C47A064D4dd0; // WS<->SHADOW, Legacy
    address USDC_WETH = 0xCfD41dF89D060b72eBDd50d65f9021e4457C477e; // USDC<->WETH, V3
    address WS_WETH = 0xB6d9B069F6B96A507243d501d1a23b3fCCFC85d3; // WS<->WETH, V3
    address WS_USDT = 0x86Be57b0419407abB4eEecb74BD1E7a919878526;

    address arnaud = vm.rememberKey(1);

    SolidlyseriesAdapter legacyAdapter;
    UniV3Adapter2 v3Adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("SONIC_RPC_URL"), 12233514);
        legacyAdapter = SolidlyseriesAdapter(payable(0x05A4D69B7e05Fb3C8904ea5158Bd2b7407e2F8e2));
        v3Adapter = new UniV3Adapter2(payable(WS)); // local deployed adapter
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

    function test_swapWStoSHADOW_Legacy() public user(arnaud) {
        deal(WS, arnaud, 1 * 10 ** 18);
        // deal(arnaud, 0.001 ether);
        IERC20(WS).approve(tokenApprove, 1 * 10 ** 18);

        console2.log(
            "WS balance before",
            IERC20(WS).balanceOf(address(arnaud))
        );
        console2.log(
            "SHADOW balance before",
            IERC20(SHADOW).balanceOf(address(arnaud))
        );

        uint256 amount = 0.01 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WS)));
        swapInfo.baseRequest.toToken = SHADOW;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(legacyAdapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(WS_SHADOW);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WS_SHADOW))));
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
            "WS balance after",
            IERC20(WS).balanceOf(address(arnaud))
        );
        console2.log(
            "SHADOW balance after",
            IERC20(SHADOW).balanceOf(address(arnaud))
        );
    }

    function test_swapSHADOWtoWS_Legacy() public user(arnaud) {
        deal(SHADOW, arnaud, 1 * 10 ** 18);
        // deal(arnaud, 0.001 ether);
        IERC20(SHADOW).approve(tokenApprove, 1 * 10 ** 18);

        console2.log(
            "WS balance before",
            IERC20(WS).balanceOf(address(arnaud))
        );
        console2.log(
            "SHADOW balance before",
            IERC20(SHADOW).balanceOf(address(arnaud))
        );

        uint256 amount = 0.01 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(SHADOW)));
        swapInfo.baseRequest.toToken = WS;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(legacyAdapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(WS_SHADOW);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(WS_SHADOW))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(SHADOW)));

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
            "SHADOW balance after",
            IERC20(SHADOW).balanceOf(address(arnaud))
        );
    }

    function test_swapStoSHADOW_Legacy() public user(arnaud) {
        deal(arnaud, 1 ether);

        console2.log(
            "S balance before",
            arnaud.balance
        );
        console2.log(
            "SHADOW balance before",
            IERC20(SHADOW).balanceOf(address(arnaud))
        );

        uint256 amount = 0.01 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(S)));
        swapInfo.baseRequest.toToken = SHADOW;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(legacyAdapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(WS_SHADOW);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(false, uint88(10000), address(WS_SHADOW)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WS)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId{value: 0.01 ether}(
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
            "SHADOW balance after",
            IERC20(SHADOW).balanceOf(address(arnaud))
        );
    }

    function test_swapSHADOWtoS_Legacy() public user(arnaud) {
        deal(SHADOW, arnaud, 1 * 10 ** 18);
        // deal(arnaud, 0.001 ether);
        IERC20(SHADOW).approve(tokenApprove, 1 * 10 ** 18);

        console2.log(
            "S balance before",
            arnaud.balance
        );
        console2.log(
            "SHADOW balance before",
            IERC20(SHADOW).balanceOf(address(arnaud))
        );

        uint256 amount = 0.01 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(SHADOW)));
        swapInfo.baseRequest.toToken = S;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(legacyAdapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(WS_SHADOW);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(WS_SHADOW)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(SHADOW)));

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
            "SHADOW balance after",
            IERC20(SHADOW).balanceOf(address(arnaud))
        );
    }
    
    function test_swapUSDCtoWETH_CL() public user(arnaud) {
        deal(USDC, arnaud, 1 * 10 ** 6);
        // deal(arnaud, 0.001 ether);
        IERC20(USDC).approve(tokenApprove, 1 * 10 ** 6);

        console2.log(
            "USDC balance before",
            IERC20(USDC).balanceOf(address(arnaud))
        );
        console2.log(
            "WETH balance before",
            IERC20(WETH).balanceOf(address(arnaud))
        );

        uint256 amount = IERC20(USDC).balanceOf(address(arnaud));
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC)));
        swapInfo.baseRequest.toToken = WETH;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(v3Adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(v3Adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(USDC_WETH))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(USDC, WETH, uint24(3000));
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
            "USDC balance after",
            IERC20(USDC).balanceOf(address(arnaud))
        );  
        console2.log(
            "WETH balance after",
            IERC20(WETH).balanceOf(address(arnaud))
        );
    }

    function test_swapStoWETH_CL() public user(arnaud) {
        deal(arnaud, 1 ether);

        console2.log(
            "S balance before",
            arnaud.balance
        );
        console2.log(
            "WETH balance before",
            IERC20(WETH).balanceOf(address(arnaud))
        );

        uint256 amount = 0.001 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(S)));
        swapInfo.baseRequest.toToken = WETH;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(v3Adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(v3Adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WS_WETH))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(WS, WETH, uint24(3000));
        swapInfo.batches[0][0].extraData[0] = abi.encode(sqrtX96, data);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WS)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId{value: 0.001 ether}(
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
            "WETH balance after",
            IERC20(WETH).balanceOf(address(arnaud))
        );
    }

    function test_swapWETHtoS_CL() public user(arnaud) {
        deal(WETH, arnaud, 1 * 10 ** 18);
        // deal(arnaud, 0.001 ether);
        IERC20(WETH).approve(tokenApprove, 1 * 10 ** 18);

        console2.log(
            "S balance before",
            arnaud.balance
        );
        console2.log(
            "WETH balance before",
            IERC20(WETH).balanceOf(address(arnaud))
        );

        uint256 amount = 0.001 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WETH)));
        swapInfo.baseRequest.toToken = S;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(v3Adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(v3Adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(WS_WETH))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(WETH, WS, uint24(3000));
        swapInfo.batches[0][0].extraData[0] = abi.encode(sqrtX96, data);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

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
            "WETH balance after",
            IERC20(WETH).balanceOf(address(arnaud))
        );
    }

    // pool with insufficient liquidity, return WS to payer
    function test_swapStoUSDT_CL() public user(arnaud) {
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
            "USDT balance before",
            IERC20(USDT).balanceOf(address(arnaud))
        );

        uint256 amount = 1 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(S)));
        swapInfo.baseRequest.toToken = WETH;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(v3Adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(v3Adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WS_USDT))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(WS, WETH, uint24(3000));
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
            "USDT balance after",
            IERC20(USDT).balanceOf(address(arnaud))
        );
    }

    // pool with insufficient liquidity, return USDT to payer
    function test_swapUSDTtoWS_CL() public user(arnaud) {
        deal(USDT, arnaud, 10000 * 10 ** 6);
        IERC20(USDT).approve(tokenApprove, 10000 * 10 ** 6);

        console2.log(
            "USDT balance before",
            IERC20(USDT).balanceOf(address(arnaud))
        );
        console2.log(
            "WS balance before",
            IERC20(WS).balanceOf(address(arnaud))
        );

        uint256 amount = IERC20(USDT).balanceOf(address(arnaud));
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDT)));
        swapInfo.baseRequest.toToken = WS;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(v3Adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(v3Adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(WS_USDT))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(USDT, WS, uint24(3000));
        swapInfo.batches[0][0].extraData[0] = abi.encode(sqrtX96, data);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDT)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        console2.log(
            "USDT balance after",
            IERC20(USDT).balanceOf(address(arnaud))
        );  
        console2.log(
            "WS balance after",
            IERC20(WS).balanceOf(address(arnaud))
        );
    }
}
