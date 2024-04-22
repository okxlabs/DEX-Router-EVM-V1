pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/TraderJoeV2P1Adapter.sol";

contract TraderJoeV2P1AdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    TraderJoeV2P1Adapter adapter = TraderJoeV2P1Adapter(address(0xfAd6a9eEe5b32E9B81bb217BaeF37742B2ca5B83));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;
    address USDe = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34;
    address USDT = 0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE;
    address pool = 0x7ccD8a769d466340Fff36c6e10fFA8cf9077D988;
    address morty = vm.rememberKey(1);
    
    function setUp() public {
        vm.createSelectFork(vm.envString("MNT_RPC_URL"));
        deal(USDT, address(this), 1 * 10 ** 6);
        adapter = new TraderJoeV2P1Adapter();
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
        console2.log("USDT balance before",IERC20(USDT).balanceOf(address(morty)));
        console2.log("USDe balance before",IERC20(USDe).balanceOf(address(morty)));
        _;
        console2.log("USDT balance after",IERC20(USDT).balanceOf(address(morty)));
        console2.log("USDe balance after",IERC20(USDe).balanceOf(address(morty)));
    }   

    function test_single() public {
        console2.log("USDe beforeswap balance", IERC20(USDe).balanceOf(address(this)));
        IERC20(USDT).transfer(pool, 0.1 * 10 ** 6);
        //IERC20(USDT).transfer(address(adapter), 0.1 * 10 ** 6);
        bytes memory moreInfo = "0x";
        adapter.sellBase(address(this), pool, moreInfo);
        console2.log("USDe afterswap balance", IERC20(USDe).balanceOf(address(this)));
    }

    function test_integrate() public user(morty) tokenBalance(USDT, 100 * 10 ** 6) {
        uint fromAmount = IERC20(USDT).balanceOf(morty);
        IERC20(USDT).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(USDT));
        swapInfo.baseRequest.toToken = USDe;
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
        //assetTo
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(pool);
        //rawData
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint(
            bytes32(
                abi.encodePacked(uint8(0x00), uint88(10000), address(pool))
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "0x";
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(USDT)));
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