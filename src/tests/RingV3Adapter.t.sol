// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "lib/forge-std/src//test.sol";
import {console2} from "lib/forge-std/src//console2.sol";

import {RingV3Adapter, IERC20} from "contracts/8//adapter/RingV3Adapter.sol";

contract RingV3AdapterTest is Test {
    RingV3Adapter adapter;
    address payable WETH = payable(0x4300000000000000000000000000000000000004);
    address USDB = 0x4300000000000000000000000000000000000003;
    address DETH = 0x1Da40C742F32bBEe81694051c0eE07485fC630f6;
    address fwUSDB = 0x866f2C06B83Df2ed7Ca9C2D044940E7CD55a06d6;
    address fwDETH = 0xB0de93a54dA8a2cfCDe44a06F797aB2fb9d39fB8;
    address WETH_DETH = 0xD9CE2740FF6419e2927Ef88BCF85C85206702c23;
    address WETH_USDB = 0xE19D7669F2eAA146ad14048eE50b6176529cCB80;

    function setUp() public {
        vm.createSelectFork(
            "https://blast.blockpi.network/v1/rpc/public",
            10810700
        );
        adapter = new RingV3Adapter(WETH);
    }

    //WETH_DETH
    // function test_1() public {
    //     deal(WETH, address(this), 1 ether);
    //     console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
    //     console2.log("DETH balance", IERC20(DETH).balanceOf(address(this)));
    //     IERC20(WETH).transfer(address(adapter), 500 );
    //     adapter.sellBase(address(this), WETH_DETH, abi.encode(0,abi.encode(WETH,DETH,500)));
    //     console2.log("DETH balance", IERC20(DETH).balanceOf(address(this)));
    // }
    //USDB_DETH
    function test_2Ring() public {
        deal(USDB, address(this), 100 * 10 ** 6);
        vm.startPrank(0x44f33bC796f7d3df55040cd3C631628B560715C2);

        console2.log("USDB balance", IERC20(USDB).balanceOf(address(this)));
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
        IERC20(USDB).transfer(address(adapter), 100 * 10 ** 6);
        IERC20(WETH).transfer(address(adapter), 1 ether);
        adapter.sellQuote(
            address(this),
            WETH_USDB,
            abi.encode(0, abi.encode(USDB, WETH, 500))
        );
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
    }
}
