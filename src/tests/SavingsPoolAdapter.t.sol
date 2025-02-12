pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/SavingsPoolAdapter.sol";

contract SavingsPoolAdapterTest is Test {
    SavingsPoolAdapter adapter;
    address sUSDS = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;
    address USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
    address sGYD = 0xeA50f402653c41cAdbaFD1f788341dB7B7F37816;
    address GYD = 0xe07F9D810a48ab5c3c914BA3cA53AF14E4491e8A;
    address scrvUSD = 0x0655977FEb2f289A4aB78af67BAB0d17aAb84367;
    address crvUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
    address amy = vm.rememberKey(1);
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    DexRouter dexRouter = DexRouter(payable(0x3b3ae790Df4F312e745D270119c6052904FB6790));

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        adapter = new SavingsPoolAdapter();
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

    function _test_swapUSDStosUSDS() public user(amy) {
        deal(USDS, amy, 1 * 10 ** 18);
        console2.log("USDS balance before",IERC20(USDS).balanceOf(address(amy)));
        console2.log("sUSDS balance before",IERC20(sUSDS).balanceOf(address(amy)));

        uint fromAmount = 1 * 10 ** 18;
        IERC20(USDS).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(USDS));
        swapInfo.baseRequest.toToken = sUSDS;
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
                abi.encodePacked(uint8(0x00), uint88(10000), address(sUSDS))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDS, sUSDS);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(USDS)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("USDS balance after",IERC20(USDS).balanceOf(address(amy)));
        console2.log("sUSDS balance after",IERC20(sUSDS).balanceOf(address(amy)));
    }

    function _test_swapsUSDStoUSDS() public user(amy){
        deal(sUSDS, amy, 1 * 10 ** 18);
        console2.log("USDS balance before",IERC20(USDS).balanceOf(address(amy)));
        console2.log("sUSDS balance before",IERC20(sUSDS).balanceOf(address(amy)));
        uint fromAmount = 1 * 10 ** 18;
        IERC20(sUSDS).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(sUSDS));
        swapInfo.baseRequest.toToken = USDS;
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
                abi.encodePacked(uint8(0x80), uint88(10000), address(sUSDS))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(sUSDS, USDS);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(sUSDS)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("USDS balance after",IERC20(USDS).balanceOf(address(amy)));
        console2.log("sUSDS balance after",IERC20(sUSDS).balanceOf(address(amy)));
    }

    function _test_swapGYDtosGYD() public user(amy) {
        deal(GYD, amy, 1 * 10 ** 18);
        console2.log("GYD balance before",IERC20(GYD).balanceOf(address(amy)));
        console2.log("sGYD balance before",IERC20(sGYD).balanceOf(address(amy)));

        uint fromAmount = 1 * 10 ** 18;
        IERC20(GYD).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(GYD));
        swapInfo.baseRequest.toToken = sGYD;
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
                abi.encodePacked(uint8(0x00), uint88(10000), address(sGYD))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(GYD, sGYD);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(GYD)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("GYD balance after",IERC20(GYD).balanceOf(address(amy)));
        console2.log("sGYD balance after",IERC20(sGYD).balanceOf(address(amy)));
    }

    function _test_swapsGYDtoGYD() public user(amy){
        deal(sGYD, amy, 1 * 10 ** 18);
        console2.log("GYD balance before",IERC20(GYD).balanceOf(address(amy)));
        console2.log("sGYD balance before",IERC20(sGYD).balanceOf(address(amy)));
        uint fromAmount = 1 * 10 ** 18;
        IERC20(sGYD).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(sGYD));
        swapInfo.baseRequest.toToken = GYD;
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
                abi.encodePacked(uint8(0x80), uint88(10000), address(sGYD))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(sGYD, GYD);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(sGYD)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("GYD balance after",IERC20(GYD).balanceOf(address(amy)));
        console2.log("sGYD balance after",IERC20(sGYD).balanceOf(address(amy)));
    }

    function test_swapcrvUSDtoscrvUSD() public user(amy) {
        deal(crvUSD, amy, 1 * 10 ** 18);
        console2.log("crvUSD balance before",IERC20(crvUSD).balanceOf(address(amy)));
        console2.log("scrvUSD balance before",IERC20(scrvUSD).balanceOf(address(amy)));

        uint fromAmount = 1 * 10 ** 18;
        IERC20(crvUSD).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(crvUSD));
        swapInfo.baseRequest.toToken = scrvUSD;
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
                abi.encodePacked(uint8(0x00), uint88(10000), address(scrvUSD))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(crvUSD, scrvUSD);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(crvUSD)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("crvUSD balance after",IERC20(crvUSD).balanceOf(address(amy)));
        console2.log("scrvUSD balance after",IERC20(scrvUSD).balanceOf(address(amy)));
    }

    function test_swapscrvUSDtocrvUSD() public user(amy){
        deal(scrvUSD, amy, 1 * 10 ** 18);
        console2.log("crvUSD balance before",IERC20(crvUSD).balanceOf(address(amy)));
        console2.log("scrvUSD balance before",IERC20(scrvUSD).balanceOf(address(amy)));
        uint fromAmount = 1 * 10 ** 18;
        IERC20(scrvUSD).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(scrvUSD));
        swapInfo.baseRequest.toToken = crvUSD;
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
                abi.encodePacked(uint8(0x80), uint88(10000), address(scrvUSD))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(scrvUSD, crvUSD);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(scrvUSD)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("crvUSD balance after",IERC20(crvUSD).balanceOf(address(amy)));
        console2.log("scrvUSD balance after",IERC20(scrvUSD).balanceOf(address(amy)));
    }
}