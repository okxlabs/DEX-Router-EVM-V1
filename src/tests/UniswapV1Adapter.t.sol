// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/UniswapV1Adapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract UniswapV1AdapterTest is Test {
    DexRouter dexRouter =
        DexRouter(payable(0x7D0CcAa3Fac1e5A943c5168b6CEd828691b46B36));
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address WETH_MKR = 0x2C4Bd064b998838076fa341A83d007FC2FA50957;
    address MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address bob = vm.rememberKey(1);
    address WETH_PEPE = 0x65586DC6b7419b596A5F354f58B45fbBd7F091b0;
    address PEPE = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;

    UniswapV1Adapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 21019644);
        adapter = new UniswapV1Adapter();
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log(
            "MKR balance before",
            IERC20(MKR).balanceOf(address(_user))
        );

        console2.log(
            "WETH balance before",
            IERC20(WETH).balanceOf(address(_user))
        );
        _;
        console2.log(
            "MKR balance after",
            IERC20(MKR).balanceOf(address(_user))
        );
        console2.log(
            "WETH balance after",
            IERC20(WETH).balanceOf(address(_user))
        );
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_swapMKRToPEPE() public user(bob) tokenBalance(bob) {
        deal(MKR, bob, 1 * 10 ** 18);
        IERC20(MKR).approve(tokenApprove, 1 * 10 ** 18);

        uint256 amount = IERC20(MKR).balanceOf(bob);
        SwapInfo memory swapInfo;

        swapInfo.baseRequest.fromToken = uint256(uint160(address(MKR)));
        swapInfo.baseRequest.toToken = PEPE;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](2);

        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(
                abi.encodePacked(uint8(0x80), uint88(10000), address(WETH_MKR))
            )
        );
        swapInfo.batches[0][0].extraData = new bytes[](1); //extradata is not 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(MKR);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(MKR)));

        // 2nd hop
        swapInfo.batches[0][1].mixAdapters = new address[](1);
        swapInfo.batches[0][1].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][1].assetTo = new address[](1);
        // direct interaction with adapter
        swapInfo.batches[0][1].assetTo[0] = address(adapter);
        swapInfo.batches[0][1].rawData = new uint[](1);
        swapInfo.batches[0][1].rawData[0] = uint256(
            bytes32(
                abi.encodePacked(uint8(0x00), uint88(10000), address(WETH_MKR))
            )
        );
        swapInfo.batches[0][1].extraData = new bytes[](1); //extradata is not 0x
        swapInfo.batches[0][1].extraData[0] = abi.encode(ETH_ADDRESS);
        swapInfo.batches[0][1].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function _test_swapWETHToMKR() public user(bob) tokenBalance(bob) {
        vm.deal(bob, 1 ether);

        uint256 amount = 1 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(ETH_ADDRESS)));
        swapInfo.baseRequest.toToken = MKR;
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
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(
                abi.encodePacked(uint8(0x00), uint88(10000), address(WETH_PEPE))
            )
        );
        swapInfo.batches[0][0].extraData = new bytes[](1); //extradata is not 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(ETH_ADDRESS);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId{value: 1 ether}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }
}
