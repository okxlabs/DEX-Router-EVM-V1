// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/test.sol";
import "@dex/adapter/EulerSwapAdapter.sol";
import "@dex/interfaces/IEulerSwap.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";
import {SafeERC20} from "@dex/libraries/SafeERC20.sol";

contract EulerSwapAdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x6088d94C5a40CEcd3ae2D4e0710cA687b91c61d0));
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

    address pool = 0x98e48d708F52d29f0F09be157F597d062747e8A8; // EulerSwap
    address USDC =  0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // asset0, decimals: 6
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // asset1, decimals: 6

    address arnaud = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38); // DefaultSender

    EulerSwapAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 22878892);
        adapter = new EulerSwapAdapter(); // local deployed adapter
    }

    modifier user(address _user, address _token, uint256 _amount) {
        vm.startPrank(_user);
        console2.log("user", _user);
        deal(address(_token), _user, _amount);
        SafeERC20.safeApprove(IERC20(_token), tokenApprove, _amount);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("USDC balance before:", IERC20(USDC).balanceOf(_user));
        console2.log("USDT balance before:", IERC20(USDT).balanceOf(_user));
        _;
        console2.log("USDC balance after:", IERC20(USDC).balanceOf(_user));
        console2.log("USDT balance after:", IERC20(USDT).balanceOf(_user));
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_eulerSwapAdapter_sellBase() public user(arnaud, USDC, 1000 * 10 ** 6) tokenBalance(arnaud) {
        SwapInfo memory swapInfo = _genSwapInfo(USDC, USDT, 1000 * 10 ** 6, 0x00);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function test_eulerSwapAdapter_sellQuote() public user(arnaud, USDT, 1000 * 10 ** 6) tokenBalance(arnaud) {
        SwapInfo memory swapInfo = _genSwapInfo(USDT, USDC, 1000 * 10 ** 6, 0x80);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    // ==================== internal functions ====================
    function _genSwapInfo(address _fromToken, address _toToken, uint256 _fromTokenAmount, uint8 _direction) internal returns (SwapInfo memory swapInfo) {
        swapInfo.baseRequest.fromToken = uint256(uint160(address(_fromToken)));
        swapInfo.baseRequest.toToken = _toToken;
        swapInfo.baseRequest.fromTokenAmount = _fromTokenAmount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = _fromTokenAmount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(_direction, uint88(10000), address(pool))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(_fromToken, _toToken);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(_fromToken)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
    }
}