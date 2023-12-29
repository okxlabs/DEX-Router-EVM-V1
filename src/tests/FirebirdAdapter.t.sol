// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/FirebirdAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract FirebirdAdapterTest is Test {

    address bob = vm.rememberKey(1);

    function setUp() public {

    }

    modifier user(address _user) {
        vm.startPrank(_user);
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

    // function test_ftm_1() public user(bob) {
    //     DexRouter dexRouter = DexRouter(payable(0xf332761c673b59B21fF6dfa8adA44d78c12dEF09));
    //     address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;

    //     //swapSPIRITtoWFTM
    //     address WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    //     address SPIRIT = 0x5Cc61A78F164885776AA610fb0FE1257df78E59B;
    //     address SPIRIT_WFTM = 0xd8ce08c416e320F6478E938603cB13A2249fFDb9;

    //     vm.createSelectFork(vm.envString("FTM_RPC_URL"), 71941606);
    //     address FIREBIRD_FORMULA_ADDRESS = 0xbA926938022aEd393436635fEd939cAdf5Afe4D5; //lif3 swap
    //     FirebirdAdapter adapter = new FirebirdAdapter(FIREBIRD_FORMULA_ADDRESS);
        
    //     deal(SPIRIT, bob, 1 * 10 ** 18);
    //     IERC20(SPIRIT).approve(tokenApprove, 1 * 10 ** 18);

    //     uint256 amount = IERC20(SPIRIT).balanceOf(bob);
    //     SwapInfo memory swapInfo;
    //     swapInfo.baseRequest.fromToken = uint256(uint160(address(SPIRIT)));
    //     swapInfo.baseRequest.toToken = WFTM;
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
    //     swapInfo.batches[0][0].assetTo[0] = address(SPIRIT_WFTM);
    //     swapInfo.batches[0][0].rawData = new uint[](1);
    //     swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(SPIRIT_WFTM))));
    //     swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
    //     swapInfo.batches[0][0].extraData[0] = abi.encode(uint32(10));
    //     swapInfo.batches[0][0].fromToken = uint256(uint160(address(SPIRIT)));

    //     swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

    //     console2.log("SPIRIT balance before", IERC20(SPIRIT).balanceOf(address(bob)));
    //     console2.log("WFTM balance before", IERC20(WFTM).balanceOf(address(bob)));

    //     dexRouter.smartSwapByOrderId(
    //         swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
    //     );

    //     console2.log("SPIRIT balance after", IERC20(SPIRIT).balanceOf(address(bob)));
    //     console2.log("WFTM balance after", IERC20(WFTM).balanceOf(address(bob)));
    // }

    function test_ftm_2() public user(bob) {
        DexRouter dexRouter = DexRouter(payable(0xf332761c673b59B21fF6dfa8adA44d78c12dEF09));
        address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;

        //swapSPIRITtoWFTM
        address WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
        address SPIRIT = 0x5Cc61A78F164885776AA610fb0FE1257df78E59B;
        address SPIRIT_WFTM = 0xd8ce08c416e320F6478E938603cB13A2249fFDb9;

        vm.createSelectFork(vm.envString("FTM_RPC_URL"), 71941606);
        address FIREBIRD_FORMULA_ADDRESS = 0xbA926938022aEd393436635fEd939cAdf5Afe4D5; //lif3 swap
        FirebirdAdapter adapter = new FirebirdAdapter(FIREBIRD_FORMULA_ADDRESS);
        
        deal(WFTM, bob, 1 * 10 ** 17);
        IERC20(WFTM).approve(tokenApprove, 1 * 10 ** 17);

        uint256 amount = IERC20(WFTM).balanceOf(bob);
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WFTM)));
        swapInfo.baseRequest.toToken = SPIRIT;
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
        swapInfo.batches[0][0].assetTo[0] = address(SPIRIT_WFTM);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(SPIRIT_WFTM))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(uint32(10));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WFTM)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("SPIRIT balance before", IERC20(SPIRIT).balanceOf(address(bob)));
        console2.log("WFTM balance before", IERC20(WFTM).balanceOf(address(bob)));

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );

        console2.log("SPIRIT balance after", IERC20(SPIRIT).balanceOf(address(bob)));
        console2.log("WFTM balance after", IERC20(WFTM).balanceOf(address(bob)));
    }

}
