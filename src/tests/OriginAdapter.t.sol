pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/OriginAdapter.sol";

contract OriginAdapterTest is Test {
    OriginAdapter public adapter;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address pool = 0x85B78AcA6Deae198fBF201c82DAF6Ca21942acc6;
    address _user = 0xEA522Fe3A65874bA3CEC38e912220282b7C71E97;
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    DexRouter dexRouter = DexRouter(payable(0x3b3ae790Df4F312e745D270119c6052904FB6790));

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20526109);
        adapter = new OriginAdapter(); 
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
        console2.log("WETH balance before",IERC20(WETH).balanceOf(_user));
        console2.log("stETH balance before",IERC20(stETH).balanceOf(_user));
        _;
        console2.log("WETH balance after",IERC20(WETH).balanceOf(_user));
        console2.log("stETH balance after",IERC20(stETH).balanceOf(_user));
    }

    function test_stETH2WETH() public user(_user) tokenBalance(){
        
        uint fromAmount = 1000000000000000;
        IERC20(stETH).approve(tokenApprove, 10 ether);
        IERC20(WETH).approve(tokenApprove, 10 ether);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(stETH));
        swapInfo.baseRequest.toToken = WETH;
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
                abi.encodePacked(uint8(0x00), uint88(10000), address(pool))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(stETH, WETH);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(stETH)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_WETH2stETH() public user(_user) tokenBalance(){
        
        uint fromAmount = 1000000000000000;
        IERC20(stETH).approve(tokenApprove, 10 ether);
        IERC20(WETH).approve(tokenApprove, 10 ether);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(WETH));
        swapInfo.baseRequest.toToken = stETH;
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
                abi.encodePacked(uint8(0x00), uint88(10000), address(pool))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(WETH, stETH);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(WETH)));
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