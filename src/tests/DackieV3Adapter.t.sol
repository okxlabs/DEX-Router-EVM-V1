pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/PancakeswapV3Adapter.sol";

contract DackieSwapV3AdapterTest is Test {

    PancakeswapV3Adapter adapter;
    address WOKB = 0xe538905cf8410324e03A5A23C1c177a474D59b2b;
    address USDT = 0x1E4a5963aBFD975d8c9021ce480b42188849D41d;
    address USDTWETH = 0xa5388037b5FEf0EfCdFC9e1d6d7bC6E7e61C7082;

    function test_WOKBtoUSDC() public {
        vm.createSelectFork(vm.envString("XLAYER_RPC_URL"));
        adapter = PancakeswapV3Adapter(address(0x329F0b78D7850Db32a35043c0DA9a63b3672617C));
        deal(USDT, address(this), 1 * 10 ** 6);
        IERC20(USDT).transfer(address(adapter), 1 * 10 ** 6);
        uint160 sqrtPriceLimitX96 = 0;
        bytes memory data = abi.encode(USDT, WOKB, uint24(2500));
        bytes memory moreInfo = abi.encode(sqrtPriceLimitX96, data);
        adapter.sellBase(address(this), USDTWETH, moreInfo);
        console2.log("WOKB", IERC20(WOKB).balanceOf(address(this)));
    }
}
