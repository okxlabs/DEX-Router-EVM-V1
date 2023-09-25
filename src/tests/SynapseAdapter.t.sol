// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/adapter/SynapseAdapter.sol";


contract SynapseAdapterTest is Test {
    SynapseAdapter adapter;
    address WETH = 0x4200000000000000000000000000000000000006;
    address nETH = 0xb554A55358fF0382Fb21F0a478C3546d1106Be8c;
    address pool = 0x6223bD82010E2fB69F329933De20897e7a4C225f;
    // 2050-07-19 17:52:02
    uint256 DDL = 2541837122;


    function setUp() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 3600052);
        adapter = new SynapseAdapter();
        deal(WETH, address(this), 1 ether);
        deal(nETH, address(this), 1 ether);


        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
        console2.log("nETH balance", IERC20(nETH).balanceOf(address(this)));


    }

    function test_1() public {
        IERC20(WETH).transfer(address(adapter), 1 ether);
        console2.log("nETH balance", IERC20(nETH).balanceOf(address(this)));    
        adapter.sellBase(address(this), pool, abi.encode(WETH,nETH,DDL));
        console2.log("swap: weth->neth end");
        console2.log("nETH balance", IERC20(nETH).balanceOf(address(this)));
    }

    function test_2() public {
        IERC20(nETH).transfer(address(adapter), 1 ether);
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));    
        adapter.sellBase(address(this), pool, abi.encode(nETH,WETH,DDL));
        console2.log("swap: neth->weth end");
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
    }
 

 




}