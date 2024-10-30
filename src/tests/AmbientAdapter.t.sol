pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/AmbientAdapter2.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract AmbientAdapterTest is Test {
    DexRouter dexRouter =
        DexRouter(payable(0xF3dE3C0d654FDa23daD170f0f320a92172509127));
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address ETHFI = 0xFe0c30065B384F05761f15d0CC899D4F9F9Cc0eB;
    address PEPE = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;
    address PENDLE = 0x808507121B80c02388fAd14726482e061B8da827;
    address CrocSwapDex = 0xAaAaAAAaA24eEeb8d57D431224f73832bC34f688;

    address arnaud = vm.rememberKey(1);

    AmbientAdapter2 adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        // adapter = new AmbientAdapter2(CrocSwapDex);
        adapter = AmbientAdapter2(payable(0x184B7c07b192bF60C0c056F8fDea8b1c656C0e95));
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance() {
        console2.log(
            "USDC balance before",
            IERC20(USDC).balanceOf(address(arnaud))
        );
        console2.log(
            "USDT balance before",
            IERC20(USDT).balanceOf(address(arnaud))
        );
        console2.log(
            "WETH balance before",
            IERC20(WETH).balanceOf(address(arnaud))
        );
        console2.log(
            "ETH balance before",
            arnaud.balance
        );
        _;
        console2.log(
            "USDC balance after",
            IERC20(USDC).balanceOf(address(arnaud))
        );
        console2.log(
            "USDT balance after",
            IERC20(USDT).balanceOf(address(arnaud))
        );
        console2.log(
            "WETH balance after",
            IERC20(WETH).balanceOf(address(arnaud))
        );
        console2.log(
            "ETH balance after",
            arnaud.balance
        );
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_swapETHtoUSDC() public user(arnaud) tokenBalance {
        // deal(WETH, arnaud, 1 * 10 ** 18);
        deal(arnaud, 0.001 ether);
        // IERC20(WETH).approve(tokenApprove, 1 * 10 ** 18);

        uint256 amount = 0.001 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(ETH)));
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
        // direct interaction with vault
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(false, uint88(10000), address(0)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(address(ETH), USDC, 1);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId{value: 0.001 ether}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_swapPENDLEtoETH() public user(arnaud) tokenBalance {
        deal(PENDLE, arnaud, 1 * 10 ** 18);
        IERC20(PENDLE).approve(tokenApprove, 1 * 10 ** 18);

        uint256 amount = IERC20(PENDLE).balanceOf(arnaud);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(PENDLE)));
        swapInfo.baseRequest.toToken = address(ETH);
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
        // direct interaction with vault
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(false, uint88(10000), address(0)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(PENDLE, address(ETH), 1);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(PENDLE)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_swapUSDTtoUSDC() public user(arnaud) tokenBalance {
        deal(USDT, arnaud, 1 * 10 ** 6);
        SafeERC20.safeApprove(IERC20(USDT), tokenApprove, 1 * 10 ** 6);

        uint256 amount = IERC20(USDT).balanceOf(arnaud);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDT)));
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
        // direct interaction with vault
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(false, uint88(10000), address(0)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDT, USDC, 1);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDT)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }
}
