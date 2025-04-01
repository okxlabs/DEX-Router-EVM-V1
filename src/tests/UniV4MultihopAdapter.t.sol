// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/UniV4AdapterV2.sol";
import "@dex/interfaces/IHooks.sol";

contract UniV4MultihopTest is Test {
    struct PathKey {
        Currency inputCurrency; //每一跳兑换的token
        Currency intermediateCurrency; //每一跳兑换出的token
        uint24 fee;
        int24 tickSpacing;
    }
    //https://dashboard.tenderly.co/tx/mainnet/0xde840c27b431f80bc18bf42bab7c212bd4f2c36c7b6aa2aa7e2c9ef984587854/debugger?trace=0.3.0.0.0.0.1.1.0
    type Currency is address;
    DexRouter dexRouter = DexRouter(payable(0x3b3ae790Df4F312e745D270119c6052904FB6790));
    address token_approve = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address poolManager = 0x000000000004444c5dc75cB358380D2e3dE08A90;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDe = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    // Currency USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 fee = 500;
    int24 tickSpacing = 10;
    address amy = vm.rememberKey(1);
    UniV4AdapterV2 adapter;

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 21799331);
        adapter = new UniV4AdapterV2(poolManager, WETH);
    }
    
    struct SwapInfo {
        uint orderId;
        DexRouter.BaseRequest baseRequest;
        uint[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_ETH2USDT() public user(amy){
        deal(amy, 39977501711779046);
        uint amount = 30000000000000000;
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(address(ETH)));
        swapInfo.baseRequest.toToken = USDT;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        //batchsAmount
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(poolManager)))
        );

        swapInfo.batches[0][0].extraData = new bytes[](1);

        PathKey[] memory pathKeys = new PathKey[](1);
        pathKeys[0] = PathKey({
            inputCurrency: Currency.wrap(address(0)),
            intermediateCurrency: Currency.wrap(USDT),
            fee: 500,
            tickSpacing: 10
        });

        swapInfo.batches[0][0].extraData[0] = abi.encode(pathKeys);

        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(amy)));
        console2.log("ETH balance before", address(amy).balance);
        dexRouter.smartSwapByOrderId{value: 30000000000000000}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("USDT balance after", IERC20(USDT).balanceOf(address(amy)));
        console2.log("ETH balance after", address(amy).balance);
    }

    function test_USDT2USDe() public user(amy){
        uint amount = 1 * 10 ** 6;
        deal(USDT, amy, amount);
        SafeERC20.safeApprove(IERC20(USDT), token_approve, amount);

        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDT)));
        swapInfo.baseRequest.toToken = USDe;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        //batchsAmount
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(poolManager)))
        );

        swapInfo.batches[0][0].extraData = new bytes[](1);

        PathKey[] memory pathKeys = new PathKey[](1);
        pathKeys[0] = PathKey({
            inputCurrency: Currency.wrap(USDT),
            intermediateCurrency: Currency.wrap(USDe),
            fee: 100,
            tickSpacing: 1
        });

        swapInfo.batches[0][0].extraData[0] = abi.encode(pathKeys);

        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDT)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(amy)));
        console2.log("USDe balance before", IERC20(USDe).balanceOf(address(amy)));
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("USDT balance after", IERC20(USDT).balanceOf(address(amy)));
        console2.log("USDe balance after", IERC20(USDe).balanceOf(address(amy)));
    }

    function test_ETH2USDT2USDe() public user(amy){
        deal(amy, 39977501711779046);
        uint amount = 30000000000000000;
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(address(ETH)));
        swapInfo.baseRequest.toToken = USDe;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        //batchsAmount
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(
            uint8(0x00), // 第一跳方向
            uint88(10000), 
            address(poolManager)
          ))
        );

        swapInfo.batches[0][0].extraData = new bytes[](1);

        PathKey[] memory pathKeys = new PathKey[](2);
        pathKeys[0] = PathKey({
            inputCurrency: Currency.wrap(address(0)),
            intermediateCurrency: Currency.wrap(USDT),
            fee: 500,
            tickSpacing: 10
        });
        pathKeys[1] = PathKey({
            inputCurrency: Currency.wrap(USDT),
            intermediateCurrency: Currency.wrap(USDe),
            fee: 100,
            tickSpacing: 1
        });

        swapInfo.batches[0][0].extraData[0] = abi.encode(pathKeys);

        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("USDe balance before", IERC20(USDe).balanceOf(address(amy)));
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(amy)));
        console2.log("ETH balance before", address(amy).balance);

        dexRouter.smartSwapByOrderId{value: 30000000000000000}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        console2.log("USDe balance after", IERC20(USDe).balanceOf(address(amy)));
        console2.log("USDT balance after", IERC20(USDT).balanceOf(address(amy)));
        console2.log("ETH balance after", address(amy).balance);
    }

    function test_USDe2USDT() public user(amy){
        uint amount = 1 ether;
        deal(USDe, amy, amount);
        SafeERC20.safeApprove(IERC20(USDe), token_approve, amount);

        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDe)));
        swapInfo.baseRequest.toToken = USDT;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        //batchsAmount
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(poolManager)))
        );

        swapInfo.batches[0][0].extraData = new bytes[](1);

        PathKey[] memory pathKeys = new PathKey[](1);
        pathKeys[0] = PathKey({
            inputCurrency: Currency.wrap(USDe),
            intermediateCurrency: Currency.wrap(USDT),
            fee: 100,
            tickSpacing: 1
        });

        swapInfo.batches[0][0].extraData[0] = abi.encode(pathKeys);

        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDe)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(amy)));
        console2.log("USDe balance before", IERC20(USDe).balanceOf(address(amy)));
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("USDT balance after", IERC20(USDT).balanceOf(address(amy)));
        console2.log("USDe balance after", IERC20(USDe).balanceOf(address(amy)));
    }

    function test_USDT2ETH() public user(amy){
        deal(USDT, amy, 5201837);
        uint256 amount = 5000000;
        SafeERC20.safeApprove(IERC20(USDT), token_approve, amount);

        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDT)));
        swapInfo.baseRequest.toToken = ETH;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        //batchsAmount
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(poolManager)))
        );

        swapInfo.batches[0][0].extraData = new bytes[](1);

        PathKey[] memory pathKeys = new PathKey[](1);
        pathKeys[0] = PathKey({
            inputCurrency: Currency.wrap(USDT),
            intermediateCurrency: Currency.wrap(address(0)),
            fee: 500,
            tickSpacing: 10
        });

        swapInfo.batches[0][0].extraData[0] = abi.encode(pathKeys);

        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDT)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(amy)));
        console2.log("ETH balance before", address(amy).balance);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("USDT balance after", IERC20(USDT).balanceOf(address(amy)));
        console2.log("ETH balance after", address(amy).balance);
    }
}