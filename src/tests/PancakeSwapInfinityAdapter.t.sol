// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/PancakeSwapInfinityAdapter.sol";
//import "@dex/interfaces/IHooks.sol";

contract PancakeSwapInfinityAdapterTest is Test {
    struct SwapInfo {
        uint orderId;
        DexRouter.BaseRequest baseRequest;
        uint[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    address constant token_approve = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;
    address constant vault = 0x238a358808379702088667322f80aC48bAd5e6c4;
    address constant clPoolManager = 0xa0FfB9c1CE1Fe56963B0321B32E7A0302114058b;
    address constant binPoolManager = 0xC697d2898e0D09264376196696c51D7aBbbAA4a9;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant DEX_ROUTER = 0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4;

    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant REHA = 0x4c067DE26475E1CeFee8b8d1f6E2266b33a2372E;
    address constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant BNB = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    DexRouter dexRouter = DexRouter(payable(DEX_ROUTER));
    address amy = vm.rememberKey(1);
    PancakeSwapInfinityAdapter adapter;

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 55909933);
        adapter = new PancakeSwapInfinityAdapter(
            IVault(vault),
            WBNB,
            clPoolManager,
            binPoolManager
        );
    }

    function test_USDT2REHA_CLPool() public user(amy) {
        //pool id : 0x097d4fdde3236f32dd8275170e1e78abaf3d9eff920ad66ecc3d01ef37c7dad0
        address FROM_TOKEN = USDT;
        address TO_TOKEN = REHA;
        uint24 fee = 16064;
        uint256 tickSpacing = 2;
        uint256 amount = 100_000;

        deal(FROM_TOKEN, amy, amount);
        SafeERC20.safeApprove(IERC20(FROM_TOKEN), token_approve, amount);

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(FROM_TOKEN)));
        swapInfo.baseRequest.toToken = TO_TOKEN;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp + 1 hours;

        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(FROM_TOKEN, TO_TOKEN, clPoolManager, fee, tickSpacing);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(FROM_TOKEN)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("=== USDT/REHA CL Pool Test (Block 55909933) ===");
        console2.log("USDT balance before", IERC20(FROM_TOKEN).balanceOf(address(amy)));
        console2.log("REHA balance before", IERC20(TO_TOKEN).balanceOf(address(amy)));

        try dexRouter.smartSwapByOrderId{value: 0}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        ) {
            console2.log("Swap succeeded");
        } catch Error(string memory reason) {
            console2.log("Swap failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console2.log("Swap failed with low level error");
        }

        console2.log("USDT balance after", IERC20(FROM_TOKEN).balanceOf(address(amy)));
        console2.log("REHA balance after", IERC20(TO_TOKEN).balanceOf(address(amy)));
    }


    function test_BNB2CAKE_CLPool() public user(amy) {    
        //pool id : 0xcbd4959ff2c7a4191b8e359e9775f89554ec104d6cfdfa9d722871e385a4489a
        address FROM_TOKEN = BNB;
        address TO_TOKEN = CAKE;
        uint24 fee = 670;
        int24 tickSpacing = 1;
        uint256 amount = 0.001 ether; // 0.001 BNB

        deal(amy, amount);

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(FROM_TOKEN));
        swapInfo.baseRequest.toToken = TO_TOKEN;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp + 1 hours;

        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));

        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(address(0), TO_TOKEN, clPoolManager, fee, tickSpacing);

        swapInfo.batches[0][0].fromToken = uint256(uint160(WBNB));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("=== BNB/CAKE CL Pool Test (Block 55909933) ===");
        console2.log("BNB balance before:", amy.balance);
        console2.log("CAKE balance before:", IERC20(TO_TOKEN).balanceOf(amy));

        try dexRouter.smartSwapByOrderId{value: amount}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        ) {
            console2.log("Swap succeeded");
        } catch Error(string memory reason) {
            console2.log("Swap failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console2.log("Swap failed with low level error");
            bytes4 selector;
            assembly {
                selector := mload(add(lowLevelData, 32))
            }
            console2.logBytes4(selector);
        }

        console2.log("BNB balance after:", amy.balance);
        console2.log("CAKE balance after:", IERC20(TO_TOKEN).balanceOf(amy));
    }

    function test_BNB2CAKE_BinPool() public user(amy) {
        //pool id : 0x1456eb94326c4bc07c73f18fc8b43494a64efa6217867581634802e87d2cab4f
        address TO_TOKEN = CAKE;
        uint24 fee = 67;
        uint256 binStep = 1;
        uint256 amount = 0.01 ether;

        deal(amy, amount);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(BNB)));
        swapInfo.baseRequest.toToken = TO_TOKEN;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp + 1 hours;
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(address(0), TO_TOKEN, binPoolManager, fee, binStep);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WBNB)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("=== BNB/CAKE Bin Pool Test (Block 55909933) ===");
        console2.log("BNB balance before", amy.balance);
        console2.log("CAKE balance before", IERC20(TO_TOKEN).balanceOf(address(amy)));

        try dexRouter.smartSwapByOrderId{value: amount}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        ) {
            console2.log("Swap succeeded");
        } catch Error(string memory reason) {
            console2.log("Swap failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console2.log("Swap failed with low level error");
        }

        console2.log("BNB balance after", amy.balance);
        console2.log("CAKE balance after", IERC20(TO_TOKEN).balanceOf(address(amy)));
    }

    function test_USDT2USDC_BinPool() public user(amy) {        
        //pool id : 0xa859b22e97f32d4c7b1d9788044697712cb7183d294ed7aa1832799c1739e5cf
        address FROM_TOKEN = USDT;
        address TO_TOKEN = USDC;
        uint24 fee = 67;
        uint256 binStep = 1;
        uint256 amount = 1000000; // 1 USDT (6 decimals)

        deal(FROM_TOKEN, amy, amount);
        SafeERC20.safeApprove(IERC20(FROM_TOKEN), token_approve, amount);

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(FROM_TOKEN)));
        swapInfo.baseRequest.toToken = TO_TOKEN;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp + 1 hours;
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(FROM_TOKEN, TO_TOKEN, binPoolManager, fee, binStep);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(FROM_TOKEN)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("=== USDT/USDC Bin Pool Test (Block 55909933) ===");
        console2.log("USDT balance before", IERC20(FROM_TOKEN).balanceOf(address(amy)));
        console2.log("USDC balance before", IERC20(TO_TOKEN).balanceOf(address(amy)));

        try dexRouter.smartSwapByOrderId{value: 0}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        ) {
            console2.log("Swap succeeded");
        } catch Error(string memory reason) {
            console2.log("Swap failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console2.log("Swap failed with low level error");
            bytes4 selector;
            assembly {
                selector := mload(add(lowLevelData, 32))
            }
            console2.logBytes4(selector);
        }

        console2.log("USDT balance after", IERC20(FROM_TOKEN).balanceOf(address(amy)));
        console2.log("USDC balance after", IERC20(TO_TOKEN).balanceOf(address(amy)));
    }
} 