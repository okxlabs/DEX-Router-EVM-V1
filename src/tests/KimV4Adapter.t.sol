// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/KimV4Adapter.sol";

contract KimV4AdapterTest is Test {
    KimV4Adapter adapter;
    address pool = 0xb3E3576aC813820021b1d1157Ec2285ab5C67D15;
    address payable WETH = payable(0x4200000000000000000000000000000000000006); 
    address USDC = 0xd988097fb8612cc24eeC14542bC03424c656005f;
    address KIM = 0x6863fb62Ed27A9DdF458105B507C15b5d741d62e;
    function setUp() public {
        vm.createSelectFork(vm.envString("MODE_RPC_URL"));
        adapter = new KimV4Adapter(WETH);
        deal(KIM, address(this), 1 ether);
        deal(USDC, address(this), 1000 * 10**6);
    }
    function test_sellKIM() public {
        IERC20(KIM).transfer(address(adapter), 1 ether);
        adapter.sellBase(address(this), pool, abi.encode(0, abi.encode(KIM, USDC)));
        console2.log("USDC", IERC20(USDC).balanceOf(address(this)) - 1000 * 10**6);
    }
    function test_sellUSDC() public {
        IERC20(USDC).transfer(address(adapter), 1000 * 10**6);
        adapter.sellBase(address(this), pool, abi.encode(0, abi.encode(USDC, KIM)));
        console2.log("KIM", IERC20(KIM).balanceOf(address(this)) - 1 ether);
    }

}