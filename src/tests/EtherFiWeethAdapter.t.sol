pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/EtherFiWeethAdapter.sol";

contract EtherFiWeethAdapterTest is Test {
    EtherFiWeethAdapter adapter;
    address constant weETH = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address constant eETH = 0x35fA164735182de50811E8e2E824cFb9B6118ac2;
    address bob = vm.rememberKey(1);
    address morty = 0xA86e3D1C80a750A310b484FB9bDc470753A7506F;
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    DexRouter dexRouter = DexRouter(payable(0x1Ef032a3c471a99CC31578c8007F256D95E89896));

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");
        // adapter = new EtherFiWeethAdapter(weETH);
        adapter = EtherFiWeethAdapter(0x51a9c09D0b83Df1978b16D71A9b1235aE8672cEF);
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
        console2.log("weETH balance before",IERC20(weETH).balanceOf(address(_user)));
        console2.log("eETH balance before",IERC20(eETH).balanceOf(address(_user)));
        _;
        console2.log("weETH balance after",IERC20(weETH).balanceOf(address(_user)));
        console2.log("eETH balance after",IERC20(eETH).balanceOf(address(_user)));
    }

    function test_swapeETHtoweETH() public user(morty) tokenBalance(morty)
    {
        // deal(eETH, bob, 1 * 10 ** 18);
        // uint fromAmount = IERC20(eETH).balanceOf(morty);
        uint fromAmount = 1 * 10 ** 18;
        IERC20(eETH).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(eETH));
        swapInfo.baseRequest.toToken = weETH;
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
                abi.encodePacked(uint8(0x00), uint88(10000), weETH)
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "";
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(eETH)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_swapweETHtoeETH() public user(bob) tokenBalance(bob)
    {
        deal(weETH, bob, 1 * 10 ** 18);
        uint fromAmount = 1 * 10 ** 18;
        IERC20(weETH).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(weETH));
        swapInfo.baseRequest.toToken = eETH;
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
                abi.encodePacked(uint8(0x80), uint88(10000), weETH)
            )
        );
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "";
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(weETH)));
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