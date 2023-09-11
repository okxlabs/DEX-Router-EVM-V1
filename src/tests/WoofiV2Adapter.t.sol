// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/WoofiAdapter.sol";


contract WoofiAdapterTest is Test {

    WoofiAdapter adapter;
    address WETH = 0x4200000000000000000000000000000000000006;
    address USDC = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
    address pool = 0xb130a49065178465931d4f887056328CeA5D723f;  


    function setUp() public{
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 3600052);
        adapter = new WoofiAdapter();
        deal(WETH, address(this), 1 ether);
        deal(USDC, address(this), 10 * 10**6);
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(adapter)));
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(pool)));


    }
    //WETH-USDC test
    function test_1() public {
        IERC20(WETH).transfer(address(adapter), 0.001 ether);
        console2.log("test1 start");
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));    
        adapter.sellQuote(address(this), pool, abi.encode(WETH,USDC));
        console2.log("swap: weth->usdc end");
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));

    }
    function test_2() public {
        IERC20(USDC).transfer(address(adapter), 10* 10**6);
        console2.log("test2 start");
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));    
        adapter.sellBase(address(this), pool, abi.encode(USDC,WETH));
        console2.log("swap: usdc->weth end");
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));

    }







}



