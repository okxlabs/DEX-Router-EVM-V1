pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/sFRAXAdapter.sol";

contract sFRAXAdapterTest is Test {
    address constant sFRAX = 0xA663B02CF0a4b149d2aD41910CB81e23e1c41c32;
    address constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

    address alice = vm.rememberKey(1);
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    DexRouter dexRouter = DexRouter(payable(0x3b3ae790Df4F312e745D270119c6052904FB6790));

    sFRAXAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        // adapter = new sFRAXAdapter(sFRAX);
        adapter = sFRAXAdapter(payable(0x414F6d5cf73a96dcBb0BFc6D1C567f3e8a382Dc0));
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

    modifier tokenBalance() {
        console2.log("FRAX balance before",IERC20(FRAX).balanceOf(address(alice)));
        console2.log("sFRAX balance before",IERC20(sFRAX).balanceOf(address(alice)));
        _;
        console2.log("FRAX balance after",IERC20(FRAX).balanceOf(address(alice)));
        console2.log("sFRAX balance after",IERC20(sFRAX).balanceOf(address(alice)));
    }

    function test_swapFRAXtosFRAX() public user(alice) tokenBalance {
        deal(FRAX, alice, 1 * 10 ** 18);

        uint fromAmount = IERC20(FRAX).balanceOf(alice);
        IERC20(FRAX).approve(tokenApprove, fromAmount);

        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(FRAX));
        swapInfo.baseRequest.toToken = sFRAX;
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
                abi.encodePacked(uint8(0x00), uint88(10000), address(0))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode("0x");
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(FRAX)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_swapsFRAXtoFRAX() public user(alice) tokenBalance {
        deal(sFRAX, alice, 1 * 10 ** 18);

        uint fromAmount = IERC20(sFRAX).balanceOf(alice);
        IERC20(sFRAX).approve(tokenApprove, fromAmount);

        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(sFRAX));
        swapInfo.baseRequest.toToken = FRAX;
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
                abi.encodePacked(uint8(0x80), uint88(10000), address(0))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode("0x");
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(sFRAX)));
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