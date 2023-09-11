// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "forge-std/test.sol";

import "@dex/adapter/KokonutAdapter.sol";
import "@dex/adapter/UniAdapter.sol";

contract KokonutAdapterTest is Test {
    KokonutAdapter adapter;
    UniAdapter adapterv2;
    address WETH = 0x4200000000000000000000000000000000000006;
    address USDC = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
    address KOKOS = 0x7901FcDbBF3a6fc7B9E79eBE2B78909216Cd3a39;
    address BALD = 0x27D2DECb4bFC9C76F0309b8E88dec3a601Fe25a8;
    address pool = 0x73c3A78E5FF0d216a50b11D51B262ca839FCfe17;  // WETH-USDC
    address pool1 = 0x1Be69BA963c2D28954E7b79749475354b64b674f; // WETH-KOKOS
    address pool2 = 0x94b1474b4275369Fd2DcB977c98c376044Ebcf5e; // WETH-KOKOs
    address pool3 = 0x6C2c8bBa83CDd3814a41a356ba186f69217B8B8f; // WETH-BALD




    function setUp() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 3600052);
        adapter = new KokonutAdapter();
        adapterv2 = new UniAdapter();
        deal(WETH, address(this), 1 ether);
        deal(USDC, address(this), 10 * 10**6);
        deal(KOKOS, address(this), 16 * 10**18);
        deal(BALD, address(this), 1000 * 10**18);
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(adapter)));
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(pool)));
    }
 
    //WETH-USDC test
    function test_1() public {
        IERC20(WETH).transfer(address(adapter), 0.001 ether);
        console2.log("test1 start");
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));    
        adapter.sellBase(address(this), pool, abi.encode(WETH,USDC,uint256(1),uint256(0)));
        console2.log("swap: weth->usdc end");
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));


    }
    
    function test_2() public {
        IERC20(USDC).transfer(address(adapter), 10 * 10**6);
        console2.log("test2 start");
        console2.log("WETH Balance before ", IERC20(WETH).balanceOf(address(this)));
        adapter.sellBase(address(this), pool, abi.encode(USDC,WETH,uint256(0),uint256(1)));
        console2.log("swap: usdc->weth end");
        console2.log("WETH balance after ", IERC20(WETH).balanceOf(address(this)));


    }

    //WETH-KOKOS test
    function test_3() public{
        IERC20(WETH).transfer(address(adapter), 0.001 ether);
        console2.log("test3 start");
        console2.log("KOKOS balance", IERC20(KOKOS).balanceOf(address(this)));    
        adapter.sellBase(address(this), pool1, abi.encode(WETH,KOKOS,uint256(0),uint256(1)));
        console2.log("swap: weth->kokos end");
        console2.log("KOKOS balance", IERC20(KOKOS).balanceOf(address(this)));

    }

    function test_4() public{
        IERC20(KOKOS).transfer(address(adapter), 16* 10**18);
        console2.log("test4 start");
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));    
        adapter.sellBase(address(this), pool1, abi.encode(KOKOS,WETH,uint256(1),uint256(0)));
        console2.log("swap: kokos-weth end");
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));

    }


    //WETH-KOKOS 
    function test_5() public{
        IERC20(KOKOS).transfer(address(pool2), 16* 10**18);
        console2.log("test5 start");
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));    
        adapterv2.sellQuote(address(this), pool2,"");
        console2.log("swap: weth-kokos end");
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));


    }
    
    function test_6() public{
        IERC20(WETH).transfer(address(pool2), 1 ether);
        console2.log("test6 start");
        console2.log("KOKOS balance", IERC20(KOKOS).balanceOf(address(this)));    
        adapterv2.sellBase(address(this), pool2,"");
        console2.log("swap: kokos-weth end");
        console2.log("KOKOS balance", IERC20(KOKOS).balanceOf(address(this)));


    }
    
    // BALD-WETH
    function test_7() public{
        IERC20(BALD).transfer(address(pool3), 1000*10**18);
        console2.log("test7 start");
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));    
        adapterv2.sellBase(address(this), pool3,"");
        console2.log("swap: BALD-WETH end");
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));


    }

    function test_8() public{
        IERC20(WETH).transfer(address(pool3), 0.005 ether);
        console2.log("test8 start");
        console2.log("BALD balance", IERC20(BALD).balanceOf(address(this)));    
        adapterv2.sellQuote(address(this), pool3,"");
        console2.log("swap: WETH-BALD end");
        console2.log("BALD balance", IERC20(BALD).balanceOf(address(this)));


    }
    
    //[FAIL. Reason: not correct index]
    function test_9() public {
        IERC20(WETH).transfer(address(adapter), 0.001 ether);
        console2.log("test1 start");
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));    
        adapter.sellBase(address(this), pool, abi.encode(WETH,USDC,uint256(0),uint256(1)));
        console2.log("swap: weth->usdc end");
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));


    }

    //[FAIL. Reason: not correct]
    function test_10() public {
        IERC20(WETH).transfer(address(adapter), 0.001 ether);
        console2.log("test1 start");
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));    
        adapter.sellBase(address(this), pool, abi.encode(WETH,USDC,uint256(1),uint256(1)));
        console2.log("swap: weth->usdc end");
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));


    }
    

}
