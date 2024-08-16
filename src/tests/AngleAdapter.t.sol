// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/AngleAdapter.sol";

/// @title AngleAdapterTest
/// @notice Do the usability test of AngleAdapter on Eth
/// @dev Explain to a developer any extra details

contract AngleAdapterTest is Test {
    AngleAdapter adapter;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDA = 0x0000206329b97DB379d5E1Bf586BbDB969C63274;
    address EURA = 0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8;
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address USDA_USDC = 0x222222fD79264BBE280b4986F6FEfBC3524d0137;
    address EURA_BC3M = 0x00253582b2a3FE112feEC532221d9708c64cEFAb;
    address BC3M = 0x2F123cF3F37CE3328CC9B5b8415f9EC5109b45e7;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        adapter = new AngleAdapter();
    }
 
    function test_1() public {
        deal(USDA, address(this), 1 * 10**6);
        bytes memory moreInfo = abi.encode(USDA, USDC);
        //bytes memory moreInfo = abi.encode(BC3M, EURA);
        IERC20(USDA).transfer(address(adapter), 1 * 10**6);
        //console2.log("USDA before:", IERC20(USDA).balanceOf(address(this)));
        console2.log("USDC before:", IERC20(USDC).balanceOf(address(this)));
        adapter.sellBase(address(this), USDA_USDC , moreInfo);
        //adapter.sellBase(address(this), USDA_USDC , moreInfo);
        //console2.log("USDA after", IERC20(USDA).balanceOf(address(this)));
        console2.log("USDC after", IERC20(USDC).balanceOf(address(this)));
    }

}