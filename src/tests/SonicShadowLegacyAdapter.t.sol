pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";

import "@dex/adapter/SolidlyseriesAdapter.sol";
import "@dex/interfaces/ISolidlyseries.sol";

contract SonicShadowLegacyAdapter is Test {
    SolidlyseriesAdapter adapter;
    address WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address SHADOW = 0x3333b97138D4b086720b5aE8A7844b1345a33333;
    address WSSHADOW = 0xF19748a0E269c6965a84f8C98ca8C47A064D4dd0;

    function setUp() public {
        vm.createSelectFork(vm.envString("SONIC_RPC_URL"), 10486006);
        adapter = new SolidlyseriesAdapter();
        deal(WS, address(this), 1 * 10 ** 18);
    }

    function test_1() public {
        console2.log("WS beforeswap balance", IERC20(WS).balanceOf(address(this)));
        console2.log("SHADOW beforeswap balance", IERC20(SHADOW).balanceOf(address(this)));
        IERC20(WS).transfer(WSSHADOW, 0.1 * 10 ** 18);
        bytes memory moreInfo = "0x";
        adapter.sellBase(address(this), WSSHADOW, moreInfo);
        console2.log("WS afterswap  balance", IERC20(WS).balanceOf(address(this)));
        console2.log("SHADOW afterswap  balance", IERC20(SHADOW).balanceOf(address(this)));
    }
}