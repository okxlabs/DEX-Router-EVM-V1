// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/PancakeswapV3Adapter.sol";

/// @title PancakeswapV3LineaTest
/// @notice Do the usability test of PancakeswapV3 adapter on Linea
/// @dev Explain to a developer any extra details

contract PancakeswapV3AdapterTest is Test {
    PancakeswapV3Adapter adapter;
    address payable WETH = payable (0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f);
    address USDC = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address USDT = 0xA219439258ca9da29E9Cc4cE5596924745e12B93;
    address WBTC = 0x3aAB2285ddcDdaD8edf438C1bAB47e1a9D05a9b4; 
    address DAI = 0x4AF15ec2A0BD43Db75dd04E62FAA3B8EF36b00d5;
 
    address USDC_WETH = 0xd5539D0360438a66661148c633A9F0965E482845;
    address USDC_USDT = 0x6a72F4F191720c411Cd1fF6A5EA8DeDEC3A64771;
    address WBTC_WETH = 0xbD3bc396C9393e63bBc935786Dd120B17F58Df4c;
    address DAI_USDC = 0xA48E0630B7b9dCb250112143C9D0fe47d26CB1e4;
    address factoryAddr = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;

    function setUp() public {
        vm.createSelectFork(vm.envString("LINEA_RPC_URL"),483486);
        adapter = new PancakeswapV3Adapter(WETH,factoryAddr);
    }
 
    //WETH-USDC 
    function test_1() public {
        deal(WETH, address(this), 1 ether);
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));  
        IERC20(WETH).transfer(address(adapter), 1 ether);
        adapter.sellQuote(address(this), USDC_WETH, abi.encode(0,abi.encode(WETH,USDC,500)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));
    }
    
    // WETH-WBTC
    function test_2() public {
        deal(WETH, address(this), 1 ether);
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
        console2.log("WBTC balance", IERC20(WBTC).balanceOf(address(this)));    
        IERC20(WETH).transfer(address(adapter), 1 ether);
        adapter.sellQuote(address(this), WBTC_WETH, abi.encode(0,abi.encode(WETH,WBTC,500)));
        console2.log("WBTC balance", IERC20(WBTC).balanceOf(address(this)));
    }

    // USDC-USDT
    function test_3() public {
        deal(USDT, address(this), 100 * 10 ** 6);
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));    
        IERC20(USDT).transfer(address(adapter), 100 * 10 ** 6);
        adapter.sellBase(address(this), USDC_USDT, abi.encode(0,abi.encode(USDT,USDC,100)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));
    }

    // USDT-DAI
    function test_4() public {
        deal(USDC, address(this), 100 * 10 ** 6);
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(this)));
        console2.log("DAI balance", IERC20(DAI).balanceOf(address(this)));    
        IERC20(USDC).transfer(address(adapter), 100 * 10 ** 6);
        adapter.sellBase(address(this), DAI_USDC, abi.encode(0,abi.encode(USDC,DAI,100)));
        console2.log("DAI balance", IERC20(DAI).balanceOf(address(this)));
    }





}