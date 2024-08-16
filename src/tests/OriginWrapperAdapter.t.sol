pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/OriginWrapperAdapter.sol";

contract OriginWrapperAdapterTest is Test {
    OriginWrapperAdapter adapter;
    address OETH = 0x856c4Efb76C1D1AE02e20CEB03A2A6a08b0b8dC3;
    address WOETH = 0xDcEe70654261AF21C44c093C300eD3Bb97b78192;
    address morty = vm.rememberKey(1);
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    DexRouter dexRouter = DexRouter(payable(0x3b3ae790Df4F312e745D270119c6052904FB6790));

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20532682);
        adapter = new OriginWrapperAdapter();
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
        console2.log("OETH balance before",IERC20(OETH).balanceOf(address(morty)));
        console2.log("WOETH balance before",IERC20(WOETH).balanceOf(address(morty)));
        _;
        console2.log("OETH balance after",IERC20(OETH).balanceOf(address(morty)));
        console2.log("WOETH balance after",IERC20(WOETH).balanceOf(address(morty)));
    }

    function test_swapOETHtoWOETH() public {   
        address user = 0x8E02247D3eE0E6153495c971FFd45Aa131f4D7cB;
        vm.startPrank(user);
        console2.log("OETH balance before",IERC20(OETH).balanceOf(user));
        console2.log("WOETH balance before",IERC20(WOETH).balanceOf(user));
        uint fromAmount = 1 ether;
        IERC20(OETH).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(OETH));
        swapInfo.baseRequest.toToken = WOETH;
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
                abi.encodePacked(uint8(0x00), uint88(10000), address(WOETH))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(OETH);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(OETH)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        vm.stopPrank();
        console2.log("OETH amount", IERC20(OETH).balanceOf(user));
        console2.log("WOETH amount", IERC20(WOETH).balanceOf(user));
    }

    function test_swapWOETHtoOETH() public user(morty) tokenBalance(WOETH, 1 * 10 ** 18)
    {
        uint fromAmount = IERC20(WOETH).balanceOf(morty);
        IERC20(WOETH).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(WOETH));
        swapInfo.baseRequest.toToken = OETH;
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
                abi.encodePacked(uint8(0x80), uint88(10000), address(WOETH))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(WOETH);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(WOETH)));
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