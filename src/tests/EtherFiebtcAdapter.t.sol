pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/EtherFiEbtcAdapter.sol";

contract EtherFiEbtcAdapterTest is Test {
    EtherFiEbtcAdapter adapter;
    address constant TELLER = 0x6Ee3aaCcf9f2321E49063C4F8da775DdBd407268;
    address constant eBTC = 0x657e8C867D8B37dCC18fA4Caead9C45EB088C642;

    address constant wBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant cbBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address constant lBTC = 0x8236a87084f8B84306f72007F36F2618A5634494;

    address bob = vm.rememberKey(1);
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    DexRouter dexRouter = DexRouter(payable(0x1Ef032a3c471a99CC31578c8007F256D95E89896));

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");
        // adapter = new EtherFiEbtcAdapter(TELLER, eBTC);
        adapter = EtherFiEbtcAdapter(0xa81E889c46aa065876896f5754fBEf0132883e96);
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

    modifier tokenBalance(address _user) {
        console2.log("wBTC balance before",IERC20(wBTC).balanceOf(address(_user)));
        console2.log("eBTC balance before",IERC20(eBTC).balanceOf(address(_user)));
        _;
        console2.log("wBTC balance after",IERC20(wBTC).balanceOf(address(_user)));
        console2.log("eBTC balance after",IERC20(eBTC).balanceOf(address(_user)));
    }

    function test_swapcbBTCtoeBTC() public user(bob) tokenBalance(bob)
    {
        deal(cbBTC, bob, 1 * 10 ** 18);
        // uint fromAmount = IERC20(eETH).balanceOf(morty);
        uint fromAmount = 1 * 10 ** 18;
        IERC20(cbBTC).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(cbBTC));
        swapInfo.baseRequest.toToken = eBTC;
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
                abi.encodePacked(uint8(0x00), uint88(10000), TELLER)
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(cbBTC);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(cbBTC)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_swapeBTCtoWBTC() public user(bob) tokenBalance(bob)
    {
        deal(eBTC, bob, 1 * 10 ** 18);
        // uint fromAmount = IERC20(eETH).balanceOf(morty);
        uint fromAmount = 1 * 10 ** 18;
        IERC20(eBTC).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(eBTC));
        swapInfo.baseRequest.toToken = wBTC;
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
                abi.encodePacked(uint8(0x80), uint88(10000), TELLER)
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(eBTC);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(eBTC)));
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