// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "lib/forge-std/src//test.sol";
import {console2} from "lib/forge-std/src//console2.sol" ;

import {DragonV2Adapter, IERC20} from "contracts/8//adapter/DragonV2Adapter.sol";


contract DragonV2AdapterTest is Test{
    DragonV2Adapter adapter;
    address payable WSEI = payable (0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7);
    address token0 = 0x47459b77F758868981d829c5e91f7f1A6892b59a;
    address token1= 0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7;
    
    address token0_1 = 0x5DCc83Cb526153b8CE97c02376De2C0E83f46a07;
    
    
    

    function setUp() public {
        vm.createSelectFork(vm.envString("SEI_RPC_URL"),113008260);
        adapter = new DragonV2Adapter(WSEI);
    }
 
    //0_1 
    function test_1() public {
        deal(token0, address(this), 100 * 10 ** 6);
        console2.log("token0 balance", IERC20(token0).balanceOf(address(this)));
        console2.log("token1 balance", IERC20(token1).balanceOf(address(this)));    
        IERC20(token0).transfer(address(adapter), 100 * 10 ** 6);
        adapter.sellBase(address(this), token0_1, abi.encode(0,abi.encode(token0,token1,100)));
        console2.log("token1 balance", IERC20(token1).balanceOf(address(this)));
    }
    //1_0
    function test_2() public {
        deal(token1, address(this), 1 ether);
        console2.log("token1 balance", IERC20(token1).balanceOf(address(this)));
        console2.log("token0 balance", IERC20(token0).balanceOf(address(this)));  
        IERC20(token1).transfer(address(adapter), 1 ether);
        adapter.sellQuote(address(this), token0_1, abi.encode(0,abi.encode(token1,token0,500)));
        console2.log("token0 balance", IERC20(token0).balanceOf(address(this)));
    }
}
