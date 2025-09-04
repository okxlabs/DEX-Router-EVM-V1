// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/OkoswapAdapter.sol";
import "@dex/interfaces/IERC20.sol";
import "@dex/interfaces/IWETH.sol";
import "@dex/libraries/SafeERC20.sol";

contract OkoswapAdapterTest is Test {
    OkoswapAdapter adapter;
    DexRouter dexRouter = DexRouter(payable(0x69C236E021F5775B0D0328ded5EaC708E3B869DF));
    address token_approve = 0x8b773D83bc66Be128c60e07E17C8901f7a64F000;
    address pool = 0x41F933b2C46E4343CAe58c1f8a024DD7F3a0832F;
    
    address amy = address(0x7189562f0854a4805D36820Ad8a3050D4f8B64F7);
    address constant WOKB = 0xe538905cf8410324e03A5A23C1c177a474D59b2b;
    address constant ROUTER = 0x236e11ce039cE0DD079cB356056C9127f65586F9;
    address constant ZhongKui = 0xeAd5dCAdB47AAcc9e051A8c1462d6175BE72DF69;
    address constant OKB = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("XLAYER_RPC_URL"), 32838237);
        adapter = new OkoswapAdapter(ROUTER, WOKB);
    }

    struct SwapInfo {
        uint orderId;
        DexRouter.BaseRequest baseRequest;
        uint[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_OKB2ZhongKui() public user(amy) {
        address FROM_TOKEN = OKB;
        address TO_TOKEN = ZhongKui;
        uint256 amount = 0.15 ether;
        deal(address(amy), amount);

        SwapInfo memory swapInfo;
 
        swapInfo.baseRequest.fromToken = uint256(uint160(address(OKB)));
        swapInfo.baseRequest.toToken = TO_TOKEN;
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
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(pool)))
        );

        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(WOKB, TO_TOKEN);

        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WOKB)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        
        console2.log("OKB balance before", address(amy).balance);
        console2.log("ZhongKui balance before", IERC20(TO_TOKEN).balanceOf(address(amy)));
        
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

        console2.log("OKB balance after", address(amy).balance);
        console2.log("ZhongKui balance after", IERC20(TO_TOKEN).balanceOf(address(amy)));
    }

    function test_ZhongKui2OKB() public user(amy) {
        address FROM_TOKEN = ZhongKui;
        address TO_TOKEN = OKB;
        uint256 amount = 1000000 * 10**18;

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
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(pool)))
        );

        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(FROM_TOKEN, WOKB);

        swapInfo.batches[0][0].fromToken = uint256(uint160(address(FROM_TOKEN)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        
        console2.log("OKB balance before", address(amy).balance);
        console2.log("ZhongKui balance before", IERC20(FROM_TOKEN).balanceOf(address(amy)));
        
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

        console2.log("OKB balance after", address(amy).balance);
        console2.log("ZhongKui balance after", IERC20(FROM_TOKEN).balanceOf(address(amy)));
    }

    function test_ZhongKui2OKB2USDC() public user(amy) {
        address FROM_TOKEN = ZhongKui;
        address TO_TOKEN = OKB;
        address DEST_TOKEN = 0x74b7F16337b8972027F6196A17a631aC6dE26d22;
        uint256 amount = 1000000 * 10 ** 18;
        address pool2 = 0x01cA49E4a864C49FeDd08B464c042d02598C3538;
        address adapter2 = 0xcc96b656b6dff0B5318d53271b82B7E7183b95D2;

        SafeERC20.safeApprove(IERC20(FROM_TOKEN), token_approve, amount);

        SwapInfo memory swapInfo;

        swapInfo.baseRequest.fromToken = uint256(uint160(address(FROM_TOKEN)));
        swapInfo.baseRequest.toToken = DEST_TOKEN;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp + 1 hours;

        swapInfo.batchesAmount = new uint256[](2);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](2);

        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(pool)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "";
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(FROM_TOKEN)));

        swapInfo.batches[1] = new DexRouter.RouterPath[](1);
        swapInfo.batches[1][0].mixAdapters = new address[](1);
        swapInfo.batches[1][0].mixAdapters[0] = address(adapter2);
        swapInfo.batches[1][0].assetTo = new address[](1);
        swapInfo.batches[1][0].assetTo[0] = address(adapter2);
        swapInfo.batches[1][0].rawData = new uint256[](1);
        swapInfo.batches[1][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(pool2)))
        );
        swapInfo.batches[1][0].extraData = new bytes[](1);
        swapInfo.batches[1][0].extraData[0] = abi.encode(WOKB, DEST_TOKEN);
        swapInfo.batches[1][0].fromToken = uint256(uint160(address(WOKB)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        
        console2.log("OKB balance before", address(amy).balance);
        console2.log("ZhongKui balance before", IERC20(FROM_TOKEN).balanceOf(address(amy)));
        console2.log("USDC balance before", IERC20(DEST_TOKEN).balanceOf(address(amy)));
        
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

        console2.log("OKB balance after", address(amy).balance);
        console2.log("ZhongKui balance after", IERC20(FROM_TOKEN).balanceOf(address(amy)));
        console2.log("USDC balance after", IERC20(DEST_TOKEN).balanceOf(address(amy)));
    }
}
