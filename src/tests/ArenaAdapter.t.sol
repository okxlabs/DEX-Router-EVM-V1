// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/test.sol";
import "@dex/adapter/ArenaAdapter.sol";
import "@dex/interfaces/IArenaTokenManager.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";
import {IERC20} from "@dex/interfaces/IERC20.sol";

contract ArenaAdapterTest is Test {
    uint256 public constant GRANULARITY_SCALER = 10 ** 18; // 1 token min granularity
    
    DexRouter dexRouter = DexRouter(payable(0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4));
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    IArenaTokenManager tokenManager = IArenaTokenManager(0x8315f1eb449Dd4B779495C3A0b05e5d194446c6e);
    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address memeToken = 0x086506f0289Ba55b4004C8DBe8321049552884C6;
    uint256 memeTokenId = 76374;
    // example tx: https://snowscan.xyz/tx/0xbdd7eefd1fb6f35214853e6a029f700ffbb1bcc5add079df8ec6d787fc8b1f41

    address arnaud = vm.rememberKey(11111);

    ArenaAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("AVAX_RPC_URL"), 64424748);
        adapter = new ArenaAdapter(payable(WAVAX));
    }

    modifier user(address _user, address _token, uint256 _amount) {
        vm.startPrank(_user);
        console2.log("user", _user);
        deal(_token, _user, _amount);
        IERC20(_token).approve(tokenApprove, _amount);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance() {
        console2.log("WAVAX balance before", IERC20(WAVAX).balanceOf(address(arnaud)));
        console2.log("MemeToken balance before", IERC20(memeToken).balanceOf(address(arnaud)));
        _;
        console2.log("WAVAX balance after", IERC20(WAVAX).balanceOf(address(arnaud)));
        console2.log("MemeToken balance after", IERC20(memeToken).balanceOf(address(arnaud)));
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    uint256 memeTokenAmount = 10000 ether; // memeToken amount of buy and sell 

    // sellBase: fromToken == WAVAX, toToken == MemeToken
    function test_arenaAdapter_sellBase() public user(arnaud, WAVAX, 1 ether) tokenBalance {
        uint256 currentSupply = IERC20(memeToken).totalSupply();
        uint256 cost = tokenManager.calculateCostWithSupply(memeTokenAmount / GRANULARITY_SCALER, memeTokenId, currentSupply / GRANULARITY_SCALER);
        console2.log("cost:", cost);

        IArenaTokenManager.FeeData memory feeData = tokenManager.getFeeData(memeTokenId, cost, address(arnaud));
        cost += feeData.totalFeeAmount;
        console2.log("total cost with fee:", cost);

        SwapInfo memory swapInfo = _genSwapInfo(WAVAX, memeToken, cost, 0x00);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    // sellQuote: fromToken == MemeToken, toToken == WAVAX
    function test_arenaAdapter_sellQuote() public user(arnaud, memeToken, memeTokenAmount) tokenBalance {
        SwapInfo memory swapInfo = _genSwapInfo(memeToken, WAVAX, memeTokenAmount, 0x80);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    // sellBase: fromToken == WAVAX, toToken == MemeToken
    function test_arenaAdapter_sellBaseWithSurplusNativeToken() public user(arnaud, WAVAX, 1 ether) tokenBalance {
        uint256 currentSupply = IERC20(memeToken).totalSupply();
        uint256 cost = tokenManager.calculateCostWithSupply(memeTokenAmount / GRANULARITY_SCALER, memeTokenId, currentSupply / GRANULARITY_SCALER);
        console2.log("cost:", cost);

        IArenaTokenManager.FeeData memory feeData = tokenManager.getFeeData(memeTokenId, cost, address(arnaud));
        cost += feeData.totalFeeAmount;
        console2.log("total cost with fee:", cost);

        uint256 surplusNativeToken = 0.01 ether; // surplus nativeToken for testing

        SwapInfo memory swapInfo = _genSwapInfo(WAVAX, memeToken, cost + surplusNativeToken, 0x00);

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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(_direction, uint88(10000), address(tokenManager))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(memeTokenAmount, memeTokenId);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(_fromToken)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
    }
}