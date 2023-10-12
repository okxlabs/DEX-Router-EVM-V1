// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/KyberElasticAdapter.sol";

/// @title KyberElasticLineaTest
/// @notice Do the usability test of KyberElastic adapter on Linea
/// @dev Explain to a developer any extra details

contract KyberElasticAdapterTest is Test {
    KyberElasticAdapter adapter;
    address DAI = 0x4AF15ec2A0BD43Db75dd04E62FAA3B8EF36b00d5;
    address USDC = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address USDT = 0xA219439258ca9da29E9Cc4cE5596924745e12B93;
    address KNC = 0x3b2F62d42DB19B30588648bf1c184865D4C3B1D6;
    address payable WETH = payable (0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f);

    address DAI_USDC = 0xB6E91bA27bB6C3b2ADC31884459D3653F9293e33;
    address USDC_WETH = 0x4b21d64Cf83e56860F1739452817E4c0fa1D399D;
    address USDC_USDT = 0x189de4b78e750E525025Cd069148D7ab4DCBc978;
    address KNC_WETH = 0x712f15BbC8f6d795cD5D1DbDd3C10d370CabaB9f;

    function setUp() public{
        vm.createSelectFork(vm.envString("LINEA_RPC_URL"), 483648);
        adapter = new KyberElasticAdapter(payable(WETH));

    }
 
    //USDC_WETH
    function test_01() public {
        deal(WETH, address(this), 1 ether);
        console2.log("Before: USDC",  IERC20(USDC).balanceOf(address(this)));
        IERC20(WETH).transfer(address(adapter), 1 * 10**18);
        bytes memory data = abi.encode(WETH, USDC, uint24(0));
        adapter.sellBase(address(this), USDC_WETH, abi.encode(uint160(0), data));
        console2.log("After: USDC",  IERC20(USDC).balanceOf(address(this)));
    }

    // DAI_USDC
    function test_02() public {
        deal(DAI, address(this), 100 * 10**18);
        console2.log("Before: USDC",  IERC20(USDC).balanceOf(address(this)));
        IERC20(DAI).transfer(address(adapter), 100 * 10**18);
        bytes memory data = abi.encode(DAI, USDC, uint24(0));
        adapter.sellBase(address(this), DAI_USDC, abi.encode(uint160(0), data));
        console2.log("After: USDC",  IERC20(USDC).balanceOf(address(this)));
    }

    // USDC_USDT
    function test_03() public {
        deal(USDT, address(this), 100 * 10**6);
        console2.log("Before: USDC",  IERC20(USDC).balanceOf(address(this)));
        IERC20(USDT).transfer(address(adapter), 100 * 10**6);
        bytes memory data = abi.encode(USDT, USDC, uint24(0));
        adapter.sellBase(address(this), USDC_USDT, abi.encode(uint160(0), data));
        console2.log("After: USDC",  IERC20(USDC).balanceOf(address(this)));
  
    }
    // KNC_WETH
    function test_04() public {
        deal(KNC, address(this), 100 * 10**18);
        console2.log("Before: WETH",  IERC20(WETH).balanceOf(address(this)));
        IERC20(KNC).transfer(address(adapter), 100 * 10**18);
        bytes memory data = abi.encode(KNC, WETH, uint24(0));
        adapter.sellBase(address(this), KNC_WETH, abi.encode(uint160(0), data));
        console2.log("After: WETH",  IERC20(WETH).balanceOf(address(this)));
  
    }


}