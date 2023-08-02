// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/CamelotV3Adapter.sol";

contract CamelotV3AdapterTest is Test {
    CamelotV3Adapter adapter;
    address constant POOL_DEPLOYER = 0x89aee07E1dbaFc82f089b45FfC763738e9FfF226;
    address payable WETH = payable(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 
    address USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address WETH_USDC = 0xb7Dd20F3FBF4dB42Fd85C839ac0241D09F72955f;
    function setUp() public {
        vm.createSelectFork(vm.envString("ARBI_RPC_URL"), 115330264);
        adapter = new CamelotV3Adapter(WETH, POOL_DEPLOYER);
        deal(WETH, address(this), 1 ether);
        deal(USDC, address(this), 1000 * 10**6);
    }
    function test_sellWETH() public {
        IERC20(WETH).transfer(address(adapter), 1 ether);
        adapter.sellBase(address(this), WETH_USDC, abi.encode(0, abi.encode(WETH, USDC)));
        console2.log("USDC", IERC20(USDC).balanceOf(address(this)) - 1000 * 10**6);
    }
    function test_sellUSDC() public {
        IERC20(USDC).transfer(address(adapter), 1000 * 10**6);
        adapter.sellBase(address(this), WETH_USDC, abi.encode(0, abi.encode(USDC, WETH)));
        console2.log("WETH", IERC20(WETH).balanceOf(address(this)) - 1 ether);
    }

}