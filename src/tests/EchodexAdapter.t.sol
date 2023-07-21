// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@dex/adapter/EchodexAdapter.sol";
import "forge-std/test.sol";
import "forge-std/console2.sol";

contract EchodexAdapterTest is Test {
    EchodexAdapter public adapter;
    address factory = 0x6D1063F2187442Cc9adbFAD2f55A96B846FCB399;
    address WETH_ECP = 0x7c3892BE12ADF04DEAEC3909b2d849F341f61dBd;
    address WETH = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;
    address ECP = 0x9201f3b9DfAB7C13Cd659ac5695D12D605B5F1e6;

    function setUp() public {
        vm.createSelectFork(vm.envString("LINEA_RPC_URL"), 14541);
        adapter = new EchodexAdapter(factory);
        deal(WETH, address(this), 1 ether);
        deal(ECP, address(this), 1 ether);
    }

    function test_1() public {
        IERC20(WETH).transfer(address(adapter), 1 ether);
        adapter.sellBase(address(this), WETH_ECP, abi.encode(WETH, ECP));
        console2.log("ECP amount: ", IERC20(ECP).balanceOf(address(this)) - 1 ether);
    }

    function test_0() public {
        IERC20(ECP).transfer(address(adapter), 1 ether);
        adapter.sellBase(address(this), WETH_ECP, abi.encode(ECP, WETH));
        console2.log("WETH amount: ", IERC20(WETH).balanceOf(address(this)) - 1 ether);
    }
}
