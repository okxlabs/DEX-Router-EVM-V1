// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@dex/adapter/HorizonAdapter.sol";
import "forge-std/test.sol";
import "forge-std/console2.sol";

contract HorizonAdapterTest is Test {
    HorizonAdapter adapter;
    address factory = 0x9Fe607e5dCd0Ea318dBB4D8a7B04fa553d6cB2c5;
    address WETH_BUSD = 0xe2dF725E44ab983e8513eCfC9c3E13Bc21eA867e;
    address payable WETH = payable(0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f); //1
    address BUSD = 0x7d43AABC515C356145049227CeE54B608342c0ad; //0

    function setUp() public {
        vm.createSelectFork(vm.envString("LINEA_RPC_URL"), 15196);
        adapter = new HorizonAdapter(WETH, factory);
        deal(WETH, address(this), 1 ether);
        deal(BUSD, address(this), 1 ether);
    }

    function test_1() public {
        IERC20(WETH).transfer(address(adapter), 1 ether);
        uint24 fee = IPool(WETH_BUSD).swapFeeUnits();
        adapter.sellBase(address(this), WETH_BUSD, abi.encode(0, abi.encode(WETH, BUSD, fee)));
        console2.log("BUSD: ", IERC20(BUSD).balanceOf(address(this)) - 1 ether);
    }

    function test_0() public {
        IERC20(BUSD).transfer(address(adapter), 1 ether);
        uint24 fee = IPool(WETH_BUSD).swapFeeUnits();
        adapter.sellBase(address(this), WETH_BUSD, abi.encode(0, abi.encode(BUSD, WETH, fee)));
        console2.log("WETH: ", IERC20(WETH).balanceOf(address(this)) - 1 ether);
    }
}
