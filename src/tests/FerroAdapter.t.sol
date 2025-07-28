// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "lib/forge-std/src//test.sol";
import {console2} from "lib/forge-std/src//console2.sol" ;
import "contracts/8//adapter/FerroAdapter.sol";

contract FerroAdapterTest is Test {
    FerroAdapter adapter;
    address USDT = 0x66e428c3f67a68878562e79A0234c1F83c208770;
    address USDC = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;
    address pool = 0xa34C0fE36541fB085677c36B4ff0CCF5fa2B32d6;
    // 2050-07-19 17:52:02
    uint256 DDL = 2541837122;


    function setUp() public {
        vm.createSelectFork(vm.envString("CRONOS_RPC_URL"), 16427000);
        adapter = new FerroAdapter();
        deal(USDT, address(this), 100 * 10 ** 6);
        deal(USDC, address(this), 100 * 10 ** 6);


        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));


    }
    

    function test_1() public {
        IERC20(USDT).transfer(address(adapter), 100 * 10 ** 6);
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));    
        adapter.sellBase(address(this), pool, abi.encode(USDT,USDC,DDL));
        console2.log("swap: USDT->USDC");
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));
    }

    function test_2() public {
        IERC20(USDC).transfer(address(adapter), 100 * 10 ** 6);
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));    
        adapter.sellBase(address(this), pool, abi.encode(USDC,USDT,DDL));
        console2.log("swap: USDC->USDT");
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));
    }
 


}