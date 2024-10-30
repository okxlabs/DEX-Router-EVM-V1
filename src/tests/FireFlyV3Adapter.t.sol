// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "lib/forge-std/src//test.sol";
import {console2} from "lib/forge-std/src//console2.sol" ;

import {FireFlyV3Adapter, IERC20} from "contracts/8//adapter/FireFlyV3Adapter.sol";


contract FireFlyV3AdapterTest is Test{
    FireFlyV3Adapter adapter;
    address payable WETH = payable (0x0Dc808adcE2099A9F62AA87D9670745AbA741746);
    address USDC = 0xb73603C5d87fA094B7314C74ACE2e64D165016fb;
    address USDT = 0xf417F5A458eC102B90352F697D6e2Ac3A3d2851f;
    
    address USDT_USDC = 0xb579a0028F6505D10206a58fCfB75f0B924Ed43F;
    address USDT_WETH = 0x4fDAcc923E9cA35ABBA6eABa68A414945D7cC9D7;
    
    

    function setUp() public {
        vm.createSelectFork(vm.envString("MANTA_RPC_URL"),3554800);
        adapter = new FireFlyV3Adapter(WETH);
    }
 
    //USDT_USDC 
    function test_1() public {
        deal(USDT, address(this), 100 * 10 ** 6);
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));    
        IERC20(USDT).transfer(address(adapter), 100 * 10 ** 6);
        adapter.sellBase(address(this), USDT_USDC, abi.encode(0,abi.encode(USDT,USDC,100)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));
    }
    //USDT_WETH
    function test_2() public {
        deal(WETH, address(this), 1 ether);
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));  
        IERC20(WETH).transfer(address(adapter), 1 ether);
        adapter.sellQuote(address(this), USDT_WETH, abi.encode(0,abi.encode(WETH,USDC,500)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));
    }
}
