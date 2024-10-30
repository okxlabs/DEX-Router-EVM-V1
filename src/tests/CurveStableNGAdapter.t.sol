// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/CurveStableNGAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract CurveStableNGAdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x3b3ae790Df4F312e745D270119c6052904FB6790));
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

    // USDe-USDC
    address USDe = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address pool = 0x02950460E2b9529D0E00284A5fA2d7bDF3fA4d72;

    address eETH = 0x35fA164735182de50811E8e2E824cFb9B6118ac2;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address pool2 = 0xeAC874aeD7761460dD4c89778Ba6db7d320911a8;
    
    address bob = 0x67d71D17Df49b21CA44B9209505eCA0EedbD7AdB;

    CurveStableNGAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        // adapter = new CurveStableNGAdapter();
        adapter = CurveStableNGAdapter(payable(0xEcd7Eef15713997528896Cb5db7ec316Db4C2101));
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("USDC balance before", IERC20(USDC).balanceOf(address(_user)));
        console2.log("USDe balance before", IERC20(USDe).balanceOf(address(_user)));
        console2.log("eETH balance before", IERC20(eETH).balanceOf(address(_user)));
        console2.log("WETH balance before", IERC20(WETH).balanceOf(address(_user)));
        _;
        console2.log("USDC balance after", IERC20(USDC).balanceOf(address(_user)));
        console2.log("USDe balance after", IERC20(USDe).balanceOf(address(_user)));
        console2.log("eETH balance after", IERC20(eETH).balanceOf(address(_user)));
        console2.log("WETH balance after", IERC20(WETH).balanceOf(address(_user)));
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    // function test_swapUSDCtoUSDT() public user(bob) tokenBalance(bob) {
    //     deal(USDC, bob, 10097 * 10 ** 6);
    //     IERC20(USDC).approve(tokenApprove, 10097 * 10 ** 6);

    //     uint256 amount = IERC20(USDC).balanceOf(bob);
    //     SwapInfo memory swapInfo;
    //     swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC)));
    //     swapInfo.baseRequest.toToken = USDe;
    //     swapInfo.baseRequest.fromTokenAmount = amount;
    //     swapInfo.baseRequest.minReturnAmount = 0;
    //     swapInfo.baseRequest.deadLine = block.timestamp;

    //     swapInfo.batchesAmount = new uint[](1);
    //     swapInfo.batchesAmount[0] = amount;

    //     swapInfo.batches = new DexRouter.RouterPath[][](1);
    //     swapInfo.batches[0] = new DexRouter.RouterPath[](1);
    //     swapInfo.batches[0][0].mixAdapters = new address[](1);
    //     swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
    //     swapInfo.batches[0][0].assetTo = new address[](1);
    //     // direct interaction with pool
    //     swapInfo.batches[0][0].assetTo[0] = address(adapter);
    //     swapInfo.batches[0][0].rawData = new uint[](1);
    //     swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(pool))));
    //     swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is not 0x
    //     swapInfo.batches[0][0].extraData[0] = abi.encode(USDC, USDe, int128(1), int128(0));
    //     swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

    //     swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

    //     dexRouter.smartSwapByOrderId(
    //         swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
    //     );
    // }

    function test_swapeETHtoWETH() public user(bob) tokenBalance(bob) {
        // deal(eETH, bob, 0.01 ether);
        IERC20(eETH).approve(tokenApprove, 0.01 ether);

        uint256 amount = 0.01 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(eETH)));
        swapInfo.baseRequest.toToken = WETH;
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
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(pool2))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is not 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(eETH, WETH, int128(0), int128(1));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(eETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

}