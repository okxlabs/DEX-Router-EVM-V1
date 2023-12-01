// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/CompoundV3Adapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";
contract CompoundV3AdapterTest is Test {
    CompoundV3Adapter adapter;
    address cWETH = 0xA17581A9E3356d9A858b789D68B4d866e593aE94;
    address cUSDC = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"),18353288);
        adapter = new CompoundV3Adapter();
    }

    //WETH->cWETH
    function test_mintEth() public{
        address user = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        vm.startPrank(user);
        console2.log("cWETH balance before", IERC20(cWETH).balanceOf(user));  
        console2.log("WETH balance before", IERC20(WETH).balanceOf(user));
        IERC20(WETH).transfer(address(adapter), IERC20(WETH).balanceOf(user));
        adapter.sellBase(user, address(0), abi.encode(WETH,cWETH,true));
        console2.log("WETH balance after mint", IERC20(WETH).balanceOf(user));
        console2.log("cWETH balance after mint", IERC20(cWETH).balanceOf(user));
    }

    //cWETH->WETH
    function test_redeemEth() public {
        address user = 0x5f5ec4F83AcCC5bA176064Dbfa67D6ac74c03af2;
        vm.startPrank(user);
        console2.log("cWETH balance before", IERC20(cWETH).balanceOf(user));  
        console2.log("WETH balance before", IERC20(WETH).balanceOf(user));
        IERC20(cWETH).transfer(address(adapter), IERC20(cWETH).balanceOf(user));
        adapter.sellBase(user, address(0), abi.encode(cWETH, WETH, false));
        console2.log("WETH balance after redeem", IERC20(WETH).balanceOf(user));
        console2.log("cWETH balance after redeem", IERC20(cWETH).balanceOf(user)); 
    }

    //USDC->cUSDC
    function test_mintUsdc() public {
        deal(USDC, address(this), 10 * 1e6);
        console2.log("USDC balance before", IERC20(USDC).balanceOf(address(this)));
        console2.log("cUSDC balance before", IERC20(cUSDC).balanceOf(address(this)));  
        IERC20(USDC).transfer(address(adapter),  10 * 1e6);
        adapter.sellBase(address(this), address(0), abi.encode(USDC,cUSDC,true));
        console2.log("USDC balance after mint", IERC20(USDC).balanceOf(address(this)));
        console2.log("cUSDC balance after mint", IERC20(cUSDC).balanceOf(address(this))); 
    }

    //cUSDC->USDC
    function test_redeemUsdc() public {
        address user = 0x5B5a6FD70a7E7Df8580331F0389E95Bafa6C16F4;
        vm.startPrank(user);
        console2.log("USDC balance before", IERC20(USDC).balanceOf(user));
        console2.log("cUSDC balance before", IERC20(cUSDC).balanceOf(user));  
        IERC20(cUSDC).transfer(address(adapter), IERC20(cUSDC).balanceOf(user));
        adapter.sellBase(user, address(0), abi.encode(cUSDC,USDC,false));
        console2.log("USDC balance after redeem", IERC20(USDC).balanceOf(user));
        console2.log("cUSDC balance after redeem", IERC20(cUSDC).balanceOf(user)); 
    }
}

contract CompoundV3AdapterTestIntegrate is Test {
    DexRouter dexRouter = DexRouter(payable(0x3b3ae790Df4F312e745D270119c6052904FB6790));
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address cWETH = 0xA17581A9E3356d9A858b789D68B4d866e593aE94;
    address cUSDC = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    CompoundV3Adapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"),18353288);
        adapter = new CompoundV3Adapter();
    }
    struct SwapInfo {
        uint orderId;
        DexRouter.BaseRequest baseRequest;
        uint[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }
    function test_redeemEth() public {

        address user = 0x5f5ec4F83AcCC5bA176064Dbfa67D6ac74c03af2;
        vm.startPrank(user);
        console2.log("cWETH balance before", IERC20(cWETH).balanceOf(user));  
        console2.log("WETH balance before", IERC20(WETH).balanceOf(user));

        IERC20(cWETH).approve(tokenApprove, type(uint256).max);

        uint amount = IERC20(cWETH).balanceOf(user);

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(cWETH));
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
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint(bytes32(abi.encodePacked(false, uint88(10000),address(cWETH))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(cWETH, WETH, false);
        swapInfo.batches[0][0].fromToken = uint(uint160(address(cWETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);


        dexRouter.smartSwapByOrderId(swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData);

        console2.log("WETH balance after redeem", IERC20(WETH).balanceOf(user));
        console2.log("cWETH balance after redeem", IERC20(cWETH).balanceOf(user)); 
    }

}