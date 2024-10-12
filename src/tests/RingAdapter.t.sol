pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import {TokenApproveProxy} from "@dex/TokenApproveProxy.sol";
import {TokenApprove} from "@dex/TokenApprove.sol";
import {DexRouter, PMMLib} from "@dex/DexRouter.sol";
import {WNativeRelayer} from "@dex/utils/WNativeRelayer.sol";
import {RingAdapter, IERC20} from "@dex/adapter/RingAdapter.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract RingAdapterTest is Test {
    TokenApprove public tokenApprove;
    TokenApproveProxy public tokenApproveProxy;
    DexRouter public dexRouter;
    RingAdapter public adapter;
    WNativeRelayer public wNativeRelayer;
    address proxyAdmin = 0x358506b4C5c441873AdE429c5A2BE777578E2C6f;
    address payable WETH = payable(0x4300000000000000000000000000000000000004);
    address USDB = 0x4300000000000000000000000000000000000003;
    address fwWETH_fwUSDB = 0x9BE8a40C9cf00fe33fd84EAeDaA5C4fe3f04CbC3;
    //address SSS = 0x62126daeC113036E6a9F27E7BE2dF051140e4F03;
    //address factory = 0x24F5Ac9A706De0cF795A8193F6AB3966B14ECfE6;
    //address fwWETH_fwSSS = 0x9B76CA5b8494086a75a9Adb4531a700ec0C51120;

    function setUp0() public {
        vm.createSelectFork(vm.envString("BLAST_RPC_URL"), 3526221);

        address tokenApproveProxyImpl = address(new TokenApproveProxy());
        tokenApproveProxy = TokenApproveProxy(
            address(
                new TransparentUpgradeableProxy(tokenApproveProxyImpl, proxyAdmin, abi.encodeWithSelector(DexRouter.initialize.selector ))
            )
        );

        address tokenApproveImpl = address(new TokenApprove());
        tokenApprove = TokenApprove(
            address(
                new TransparentUpgradeableProxy(tokenApproveImpl, proxyAdmin, abi.encodeWithSelector(TokenApprove.initialize.selector, address(tokenApproveProxy)))
            )
        );

        address dexRouterImpl = address(new DexRouter());
        dexRouter = DexRouter(
            payable(
                address(
                    new TransparentUpgradeableProxy(dexRouterImpl, proxyAdmin, abi.encodeWithSelector(DexRouter.initialize.selector ))
                )
            )
        );

        address wNativeRelayerImpl = address(new WNativeRelayer());
        wNativeRelayer = WNativeRelayer(
            payable(
                address(
                    new TransparentUpgradeableProxy(wNativeRelayerImpl, proxyAdmin, abi.encodeWithSelector(WNativeRelayer.initialize.selector, WETH))
                )
            )
        );
        address[] memory whitelistedCallers = new address[](1);
        whitelistedCallers[0] = address(dexRouter);
        wNativeRelayer.setCallerOk(whitelistedCallers, true);

        tokenApproveProxy.setTokenApprove(address(tokenApprove));
        tokenApproveProxy.addProxy(address(dexRouter));
    }

    function setUp() public {
        setUp0();
        adapter = new RingAdapter(); 
        deal(USDB, address(this), 200 * 10 ** 6);
    }

    function test_adapter() public {
        USDB.call(abi.encodeWithSignature("transfer(address,uint256)", address(adapter), 200 * 10 ** 6));
        adapter.sellQuote(address(adapter), fwWETH_fwUSDB, abi.encode(USDB));
        console2.log("WETH amount", IERC20(WETH).balanceOf(address(adapter)));
    }
}

contract RingAdapterTestIntegrate is Test {
    DexRouter dexRouter =
        DexRouter(payable(0x2E86f54943faFD2cB62958c3deed36C879e3E944));
    address tokenApprove = 0x5fD2Dc91FF1dE7FF4AEB1CACeF8E9911bAAECa68;
    address fwWETH_fwUSDB = 0x9BE8a40C9cf00fe33fd84EAeDaA5C4fe3f04CbC3;
    address WETH = 0x4300000000000000000000000000000000000004;
    address USDB = 0x4300000000000000000000000000000000000003;

    RingAdapter adapter;
    address morty = vm.rememberKey(1);

    function setUp() public {
        vm.createSelectFork(vm.envString("BLAST_RPC_URL"), 3557200);
        adapter = new RingAdapter();
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

    function test_swap_USDB2WETH() public user(morty) {
        deal(USDB, morty, 100 * 10 ** 6);
        
        uint fromAmount = IERC20(USDB).balanceOf(morty);
        IERC20(USDB).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(USDB));
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
        swapInfo.batches[0][0].rawData[0] = getRawData(true, 10000, address(fwWETH_fwUSDB));
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDB);
        //fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(USDB)));
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        console2.log("WETH balance after",IERC20(WETH).balanceOf(address(morty)));
    }

    function test_swap_WETH2USDB() public {
        address user = 0x0BD4a1eC51D42C1201536877Ab03f139Ef3fd0D7;
        vm.startPrank(user);
        //deal(WETH, morty, 1 * 10 ** 18);

        uint fromAmount = IERC20(WETH).balanceOf(user);
        IERC20(WETH).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        //baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(WETH));
        swapInfo.baseRequest.toToken = USDB;
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
        swapInfo.batches[0][0].rawData[0] = getRawData(false, 10000, address(fwWETH_fwUSDB));
        //moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(WETH);
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
        console2.log("USDB balance after",IERC20(USDB).balanceOf(user));
    }

    function getRawData(bool reverse, uint256 _weight, address addr) internal returns (uint256) {
        uint256 res;
        bytes1 firstByte = bytes1(0x00);
        if (reverse) {
            firstByte = bytes1(0x80); //0b1000_0000
        }
        bytes2 weight = bytes2(uint16(_weight));
        uint256 shift = 10;
        assembly {
            weight := shr(mul(shift, 8), weight)
            res := add(firstByte, add(weight, addr))
        }
        return res;
    }
}