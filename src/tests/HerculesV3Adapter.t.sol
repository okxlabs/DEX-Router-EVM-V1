// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/HerculesV3Adapter.sol";

contract HerculesV3AdapterTest is Test {
    HerculesV3Adapter adapter;
    address payable WETH = payable(0x420000000000000000000000000000000000000A); 
    address USDC = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;
    address WETH_USDC = 0x35096c3cA17D12cBB78fA4262f3c6eff73ac9fFc;
    function setUp() public {
        vm.createSelectFork(vm.envString("METIS_RPC_URL"));
        adapter = new HerculesV3Adapter(WETH);
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