pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/sDAIAdapter.sol";

contract sDAIAdapterTest is Test {
    sDAIAdapter adapter;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address sDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address pool = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address morty = vm.rememberKey(1);
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    DexRouter dexRouter = DexRouter(payable(0x3b3ae790Df4F312e745D270119c6052904FB6790));

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        adapter = new sDAIAdapter();
    }

    struct SwapInfo {
        uint orderId;
        DexRouter.BaseRequest baseRequest;
        uint[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address fromToken, uint256 amount) {
        deal(fromToken, morty, amount);
        console2.log("DAI balance before",IERC20(DAI).balanceOf(address(morty)));
        console2.log("sDAI balance before",IERC20(sDAI).balanceOf(address(morty)));
        _;
        console2.log("DAI balance after",IERC20(DAI).balanceOf(address(morty)));
        console2.log("sDAI balance after",IERC20(sDAI).balanceOf(address(morty)));
    }

    function test_swapDAItosDAI() public user(morty) tokenBalance(DAI, 1 * 10 ** 18)
    {
        uint fromAmount = IERC20(DAI).balanceOf(morty);
        IERC20(DAI).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(DAI));
        swapInfo.baseRequest.toToken = sDAI;
        swapInfo.baseRequest.fromTokenAmount = fromAmount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        //batchsAmount
        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = fromAmount;

        //batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        //mixAdapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        //assertTo
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        //rawData
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint(
            bytes32(
                abi.encodePacked(uint8(0x00), uint88(10000), address(sDAI))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(DAI, sDAI);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(DAI)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_swapsDAItoDAI() public user(morty) tokenBalance(sDAI, 1 * 10 ** 18)
    {
        uint fromAmount = IERC20(sDAI).balanceOf(morty);
        IERC20(sDAI).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(sDAI));
        swapInfo.baseRequest.toToken = DAI;
        swapInfo.baseRequest.fromTokenAmount = fromAmount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        //batchsAmount
        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = fromAmount;

        //batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        //mixAdapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        //assertTo
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        //rawData
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint(
            bytes32(
                abi.encodePacked(uint8(0x80), uint88(10000), address(sDAI))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(sDAI, DAI);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(sDAI)));
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