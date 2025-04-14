pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/BalancerV3Adapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract SonicBeetsV3Test is Test {
    DexRouter dexRouter =
        DexRouter(payable(0x4Efa4b8545a3a77D80Da3ECC8F81EdB1a4bda783));
    address tokenApprove = 0xD321ab5589d3E8FA5Df985ccFEf625022E2DD910;

    address VAULT = 0xbA1333333333a1BA1108E8412f11850A5C319bA9;
    address USDC = 0x7870ddFd5ACA4E977B2287e9A212bcbe8FC4135a; // decimals: 6
    address scUSD = 0xd3DCe716f3eF535C5Ff8d041c1A41C3bd89b97aE; // decimals: 6
    address USDC_scUSD = 0x43026d483f42fB35efe03c20B251142D022783f2; // BalancerV3

    address arnaud = vm.rememberKey(1);
    uint256 amount = 1 * 10 ** 6;

    BalancerV3Adapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("SONIC_RPC_URL"), 12803096);
        adapter = new BalancerV3Adapter(VAULT); // local deployed adapter
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        console2.log("User:", _user);
        _;
        vm.stopPrank();
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_sonicBeetsV3_swapUSDC2scUSD_adapter() public {
        deal(USDC, address(this), amount);
        console2.log("USDC beforeswap balance", IERC20(USDC).balanceOf(address(this)));
        console2.log("scUSD beforeswap balance", IERC20(scUSD).balanceOf(address(this)));
        IERC20(USDC).transfer(address(adapter), amount);
        adapter.sellBase(address(this), USDC_scUSD, abi.encode(USDC, scUSD));
        console2.log("USDC afterswap  balance", IERC20(USDC).balanceOf(address(this)));
        console2.log("scUSD afterswap  balance", IERC20(scUSD).balanceOf(address(this)));
    }

    function test_sonicBeetsV3_swapUSDC2scUSD_dexRouter() public user(arnaud) {
        deal(USDC, arnaud, amount);
        IERC20(USDC).approve(tokenApprove, amount);
        console2.log(
            "USDC balance before",
            IERC20(USDC).balanceOf(address(arnaud))
        );
        console2.log(
            "scUSD balance before",
            IERC20(scUSD).balanceOf(address(arnaud))
        );

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC)));
        swapInfo.baseRequest.toToken = scUSD;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(USDC_scUSD))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDC, scUSD);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        console2.log(
            "USDC balance after",
            IERC20(USDC).balanceOf(address(arnaud))
        );  
        console2.log(
            "scUSD balance after",
            IERC20(scUSD).balanceOf(address(arnaud))
        );
    }
}