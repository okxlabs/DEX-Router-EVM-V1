// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "forge-std/test.sol";

import "@dex/adapter/LevelAdapter.sol";


// // ARIBITRUM _ TEST
// contract LevelAdapterTest is Test {
//     LevelAdapter adapter;
//     address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
//     address USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
//     address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
//     address WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
//     address ARB  = 0x912CE59144191C1204E64559FE8253a0e49E6548;
//     address pool_arb = 0x32B7bF19cb8b95C27E644183837813d4b595dcc6; 
 



//     function setUp() public {
//         vm.createSelectFork(vm.envString("ARB_RPC_URL"),131252635);
//         adapter = new LevelAdapter();
//         deal(WETH, address(this), 1 ether);
//         deal(USDC, address(this), 100 * 10**6);
//         deal(USDT, address(this), 100 * 10**6);
//         deal(WBTC, address(this), 1 * 10**8);
//         deal(ARB, address(this), 100 * 10**18);

//         console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
//         console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));
//         console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));
//         console2.log("WBTC balance", IERC20(WBTC).balanceOf(address(this)));
//         console2.log("ARB balance", IERC20(ARB).balanceOf(address(this)));
//     }
 
//     //WETH-USDT test
//     function test_1() public {
//         IERC20(WETH).transfer(address(pool_arb), 0.001 ether);
//         console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));    
//         adapter.sellQuote(address(this), pool_arb, abi.encode(WETH,USDT));
//         console2.log("swap: weth->usdt end");
//         console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));


//     }

//     //USDC-USDT test
//     function test_2() public {
//         IERC20(USDC).transfer(address(pool_arb), 100 * 10 ** 6);
//         console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));    
//         adapter.sellBase(address(this), pool_arb, abi.encode(USDC,USDT));
//         console2.log("swap: usdc->usdt end");
//         console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));


//     }

//     //WBTC - USDT test
//     function test_3() public {
//         IERC20(WBTC).transfer(address(pool_arb), 0.01 * 10 ** 8);
//         console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));    
//         adapter.sellQuote(address(this), pool_arb, abi.encode(WBTC,USDT));
//         console2.log("swap: WBTC>USDT end");
//         console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));


//     }
    
//     // ARB - ETH
//     function test_4() public {
//         IERC20(ARB).transfer(address(pool_arb), 100*10 **18);
//         console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));    
//         adapter.sellQuote(address(this), pool_arb, abi.encode(ARB,WETH));
//         console2.log("swap: arb->weth end");
//         console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));


//     }

//     //USDT - USDC
//     function test_5() public {
//         IERC20(USDT).transfer(address(pool_arb), 100*10 **6);
//         console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));    
//         adapter.sellBase(address(this), pool_arb, abi.encode(USDT,USDC));
//         console2.log("swap: usdt->usdc end");
//         console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));

//     }


    



    


// }

// BSC _ TEST

contract LevelAdapterTest is Test {
    LevelAdapter adapter;
    address WETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address USDT = 0x55d398326f99059fF775485246999027B3197955;
    address WBTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address BNB  = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address pool_bsc = 0xA5aBFB56a78D2BD4689b25B8A77fd49Bb0675874;




    function setUp() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"),31757045);
        adapter = new LevelAdapter();
        deal(WETH, address(this), 1 ether);
        deal(USDT, address(this), 1 ether);
        deal(WBTC, address(this), 1 ether);
        deal(BNB,  address(this), 1 ether);

        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
        console2.log("BNB balance", IERC20(BNB).balanceOf(address(this)));
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));
        console2.log("WBTC balance", IERC20(WBTC).balanceOf(address(this)));
    }
 
    //WETH-USDT test
    function test_1() public {
        IERC20(WETH).transfer(address(pool_bsc), 1 ether);
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));    
        adapter.sellQuote(address(this), pool_bsc, abi.encode(WETH,USDT));
        console2.log("swap: weth->usdt end");
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));


    }

    //BNB-USDT test
    function test_2() public {
        IERC20(BNB).transfer(address(pool_bsc), 1 ether);
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));    
        adapter.sellBase(address(this), pool_bsc, abi.encode(BNB,USDT));
        console2.log("swap: bnb->usdt end");
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));


    }

    //WBTC - USDT test
    function test_3() public {
        IERC20(WBTC).transfer(address(pool_bsc), 1 ether);
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));    
        adapter.sellQuote(address(this), pool_bsc, abi.encode(WBTC,USDT));
        console2.log("swap: wbtc>usdt end");
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));


    }
    
    // BNB - ETH test
    function test_4() public {
        IERC20(BNB).transfer(address(pool_bsc), 1 ether);
        console2.log("WETH balance", IERC20(WETH ).balanceOf(address(this)));    
        adapter.sellQuote(address(this), pool_bsc, abi.encode(BNB,WETH));
        console2.log("swap: bnb->weth end");
        console2.log("WETH balance", IERC20(WETH ).balanceOf(address(this)));


    }


}
